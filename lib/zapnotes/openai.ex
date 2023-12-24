defmodule Zapnotes.Openai do
  alias Zapnotes.Openai.Api

  def summarize_transcription(transcription) do
    with {:ok, res} <-
           Api.create_json_chat_completion([
             %{
               role: "system",
               content: system_prompt()
             },
             %{
               role: "user",
               content: transcription
             }
           ]) do
      res["choices"]
      |> Enum.at(0)
      |> get_in(["message", "content"])
      |> Jason.decode()
    end
  end

  defp system_prompt() do
    """
    You are a helpful assistant designed to create structured documents from audio transcriptions.
    The user will give you the transcription of its audio message and you should leverage markdown features
    like headings, paragraphs, bullet lists (preferred), etc with the goal of creating a detailed and logically organized document.

    Your response should contain:

    1. title: a title with a max of 50 characters summarizing the transcription
    2. summary: a simple paragraph with max 300 characters summarizing the subject of the transcription
    3. content: a markdown representing your document output

    The output of your messages should be a JSON object following the structure:

    {"title": ..., "summary": ..., "content": ...}

    The next message from the user is the audio transcript.
    """
  end
end
