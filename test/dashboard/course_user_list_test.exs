defmodule UneebeeWeb.DashboardCourseUserListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Organizations

  describe "user list (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/users")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "user list (manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "lists users", %{conn: conn, school: school, course: course} do
      assert_user_list(conn, school, course)
    end
  end

  describe "user list (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/users") end)
    end
  end

  describe "user list (school student)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :student, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/users") end)
    end
  end

  describe "user list (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "lists users", %{conn: conn, school: school, course: course} do
      assert_user_list(conn, school, course)
    end

    test "adds a user using their email address", %{conn: conn, course: course} do
      user = user_fixture(%{first_name: "Leo", last_name: "Da Vinci"})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/users")

      refute has_element?(lv, ~s|h3:fl-icontains("Leo da Vinci")|)

      {:ok, updated_lv, _html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/users")

      assert has_element?(updated_lv, ~s|h3:fl-icontains("#{user.first_name}")|)
    end

    test "adds a user using their username", %{conn: conn, course: course} do
      user = user_fixture(%{first_name: "Leo", last_name: "Da Vinci"})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/users")

      refute has_element?(lv, ~s|h3:fl-icontains("Leo da Vinci")|)

      {:ok, updated_lv, _html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.username})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/users")

      assert has_element?(updated_lv, ~s|h3:fl-icontains("#{user.first_name}")|)
    end

    test "displays an error when trying to add an unexisting user", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/users")

      result =
        lv
        |> form("#add-user-form", %{email_or_username: "unexisting"})
        |> render_submit()

      assert result =~ "User not found!"
    end
  end

  describe "user list (course student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/users") end)
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp assert_user_list(conn, school, course) do
    user1 = user_fixture(%{first_name: "User 1"})
    user2 = user_fixture(%{first_name: "User 2"})
    user3 = user_fixture(%{first_name: "User 3"})
    user4 = user_fixture(%{first_name: "User 4"})

    school_user_fixture(%{school: school, user: user1, role: :student})
    cu2 = course_user_fixture(%{course: course, user: user2, role: :student})
    cu3 = course_user_fixture(%{course: course, user: user3, role: :teacher, approved?: false})

    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/users")

    assert has_element?(lv, ~s|li[aria-current="page"] a:fl-icontains("users")|)

    assert has_element?(lv, ~s|a:fl-icontains("details")|)

    assert has_element?(lv, ~s|h3:fl-icontains("#{user2.first_name}")|)
    assert has_element?(lv, ~s|h3:fl-icontains("#{user3.first_name}")|)
    refute has_element?(lv, ~s|h3:fl-icontains("#{user1.first_name}")|)
    refute has_element?(lv, ~s|h3:fl-icontains("#{user4.first_name}")|)

    assert has_element?(lv, ~s|#users-#{cu3.id} span[role="status"]:fl-icontains("pending")|)
    refute has_element?(lv, ~s|#users-#{cu2.id} span[role="status"]:fl-icontains("pending")|)
  end
end