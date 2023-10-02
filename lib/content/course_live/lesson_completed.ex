defmodule UneebeeWeb.Live.Content.Course.LessonCompleted do
  @moduledoc false
  use UneebeeWeb, :live_view

  import Uneebee.Gamification.UserMedal.Config

  alias Uneebee.Content
  alias Uneebee.Content.UserLesson
  alias Uneebee.Gamification

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: lesson, current_user: user} = socket.assigns

    user_lesson = Content.get_user_lesson(user.id, lesson.id)
    first_lesson_today? = Gamification.first_lesson_today?(user.id)
    learning_days = Gamification.learning_days_count(user.id)
    medal = get_medal(user_lesson)

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:user_lesson, user_lesson)
      |> assign(:first_lesson_today?, first_lesson_today?)
      |> assign(:learning_days, learning_days)
      |> assign(:medal, medal)

    {:ok, socket}
  end

  defp get_score(%UserLesson{correct: correct, total: total}), do: Float.round(correct / total * 10, 1)

  defp score_title(score) when score == 10.0, do: dgettext("courses", "Perfect!")
  defp score_title(score) when score >= 9.0, do: dgettext("courses", "Excellent!")
  defp score_title(score) when score >= 8.0, do: dgettext("courses", "Very good!")
  defp score_title(score) when score >= 7.0, do: dgettext("courses", "Good!")
  defp score_title(score) when score >= 6.0, do: dgettext("courses", "Not bad!")
  defp score_title(_score), do: dgettext("courses", "There's room for improvement")

  defp score_image(score) when score == 10.0, do: ~p"/images/lessons/perfect.svg"
  defp score_image(score) when score >= 7.0, do: ~p"/images/lessons/good.svg"
  defp score_image(_score), do: ~p"/images/lessons/improve.svg"

  defp win?(score), do: score >= 6.0

  defp get_medal(%UserLesson{attempts: 1, correct: correct, total: total}) when correct == total,
    do: medal(:perfect_lesson_first_try)

  defp get_medal(%UserLesson{attempts: 1}), do: medal(:lesson_completed_with_errors)

  defp get_medal(%UserLesson{correct: correct, total: total}) when correct == total,
    do: medal(:perfect_lesson_practiced)

  defp get_medal(_user_lesson), do: nil
end
