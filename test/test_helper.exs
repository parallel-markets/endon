ExUnit.start()

defmodule UserHelpers do
  use ExUnit.Case

  def i(query) do
    assert "#Ecto.Query<" <> rest = inspect(query)
    size = byte_size(rest)
    assert ">" = :binary.part(rest, size - 1, 1)
    :binary.part(rest, 0, size - 1)
  end
end

defmodule UserSingle do
  import UserHelpers

  defmodule Repo do
    def one(input), do: i(input)
    def all(input), do: [i(input)]
    def transaction(func), do: {:ok, func.()}
  end

  use Endon, repo: Repo
  use Ecto.Schema
  schema("users", do: nil)
end

defmodule UserNone do
  import UserHelpers

  defmodule Repo do
    def one(_input), do: nil
    def all(_input), do: []
    def transaction(func), do: {:ok, func.()}
    def insert(changeset), do: {:ok, changeset.changes}
  end

  use Endon, repo: Repo
  use Ecto.Schema
  schema("users", do: nil)
end

defmodule UserDouble do
  import UserHelpers

  defmodule Repo do
    def one(input), do: [i(input), nil]
    def all(input), do: [i(input), nil]
  end

  use Endon, repo: Repo
  use Ecto.Schema
  schema("users", do: nil)
end

defmodule UserOK do
  defmodule Repo do
    def update(input), do: {:ok, input}
    def insert(input), do: {:ok, input}
    def delete(input), do: {:ok, input}
  end

  use Endon, repo: Repo
  use Ecto.Schema
  schema("users", do: nil)
end

defmodule NoPrimaryKey do
  import UserHelpers

  defmodule Repo do
    def one(input), do: [i(input), nil]
    def update(input), do: {:ok, input}
    def insert(input), do: {:ok, input}
    def delete(input), do: {:ok, input}
    def all(input), do: [i(input), nil]
  end

  use Endon, repo: Repo
  use Ecto.Schema

  @primary_key false

  schema "users" do
    field(:info, :string)
    field(:other_info, :integer)
  end
end

defmodule CompositePrimaryKey do
  import UserHelpers

  defmodule Repo do
    def one(input), do: [i(input), nil]
    def all(input), do: [i(input), nil]
  end

  use Endon, repo: Repo
  use Ecto.Schema

  @primary_key false

  schema "users" do
    field(:part_one, :integer, primary_key: true)
    field(:part_two, :integer, primary_key: true)
  end
end

defmodule UserError do
  use Endon, repo: UserError.Repo
  use Ecto.Schema
  import Ecto.Changeset

  schema("users", do: nil)

  def changeset(user, attrs) do
    cast(user, attrs, [:id])
  end
end

defmodule UserError.Repo do
  import Ecto.Changeset

  def update(input), do: {:error, input}
  def insert(input), do: {:error, input}

  def delete(input) do
    changeset =
      input
      |> UserError.changeset(%{})
      |> add_error(:id, "No such id")

    {:error, changeset}
  end
end
