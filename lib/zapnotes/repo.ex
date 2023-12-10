defmodule Zapnotes.Repo do
  use Ecto.Repo,
    otp_app: :zapnotes,
    adapter: Ecto.Adapters.Postgres
end
