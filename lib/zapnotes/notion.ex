defmodule Zapnotes.Notion do
  @database_id Application.compile_env(:zapnotes, [__MODULE__, :database_id])

  alias Zapnotes.Notion.Api

  def markdown_to_notion(markdown) do
    MartianEx.markdown_to_blocks(markdown)
  end

  def save_to_notion_audio_database(page_title, date, phone, blocks) do
    parent = %{
      type: "database_id",
      database_id: @database_id
    }

    properties = %{
      "Name" => %{
        type: "title",
        title: [%{type: "text", text: %{content: page_title}}]
      },
      "Date" => %{
        type: "date",
        date: %{start: DateTime.to_iso8601(date)}
      },
      "Phone" => %{
        type: "phone_number",
        phone_number: phone
      }
    }

    Api.create_page(parent, properties, blocks)
  end
end
