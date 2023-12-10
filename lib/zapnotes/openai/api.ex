defmodule Zapnotes.Openai.Api do
  def transcribe_with_whisper(audio_buffer) do
    model = "whisper-1"

    multipart =
      Multipart.new()
      |> Multipart.add_part(Multipart.Part.text_field(model, "model"))
      |> Multipart.add_part(
        Multipart.Part.file_content_field("audio.ogg", audio_buffer, :file, filename: "audio.ogg")
      )

    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")

    headers =
      default_headers()
      |> Map.put("Content-Type", content_type)
      |> Map.put("Content-Length", to_string(content_length))

    with {:ok, res} <-
           Req.post("https://api.openai.com/v1/audio/transcriptions",
             headers: headers,
             body: Multipart.body_stream(multipart),
             receive_timeout: 120_000,
             connect_options: [
               timeout: 120_000
             ]
           ),
         :ok <- ensure_status(res) do
      {:ok, res.body["text"]}
    end
  end

  def create_json_chat_completion(messages) do
    with {:ok, res} <-
           Req.post(base_req(),
             url: "/v1/chat/completions",
             json: %{
               model: "gpt-4-1106-preview",
               response_format: %{type: "json_object"},
               messages: messages
             },
             receive_timeout: 120_000,
             connect_options: [
               timeout: 120_000
             ]
           ),
         :ok <- ensure_status(res) do
      {:ok, res.body}
    end
  end

  defp base_req() do
    Req.new(
      base_url: "https://api.openai.com",
      headers: default_headers()
    )
  end

  defp default_headers() do
    %{
      "Authorization" => "Bearer #{token()}",
      "Accept" => "application/json"
    }
  end

  defp ensure_status(res) when res.status in 200..299 do
    :ok
  end

  defp ensure_status(res) do
    {:error, res}
  end

  defp token() do
    :zapnotes
    |> Application.fetch_env!(Zapnotes.Openai)
    |> Keyword.fetch!(:token)
  end
end
