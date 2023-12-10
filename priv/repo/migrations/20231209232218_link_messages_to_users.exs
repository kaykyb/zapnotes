defmodule Zapnotes.Repo.Migrations.LinkMessagesToUsers do
  use Ecto.Migration

  def change do
    alter table(:chat_messages) do
      add :user_id, references(:users, type: :binary_id), null: false
    end
  end
end
