defmodule Zapnotes.Accounts do
  import Ecto.Query

  alias Zapnotes.Repo
  alias Zapnotes.Accounts.User

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def get_user_for_platform_uid(platform, platform_uid) do
    from(
      u in User,
      where: u.platform == ^platform and u.platform_uid == ^platform_uid
    )
    |> Repo.one()
  end

  def create_user(%User{} = user) do
    Repo.insert(user)
  end
end
