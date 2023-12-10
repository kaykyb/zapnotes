defmodule Zapnotes.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :platform, :string
      add :platform_id, :string
      add :text, :string
      add :audio_url, :string

      timestamps()
    end
  end
end
