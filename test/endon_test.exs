defmodule EndonTest do
  use ExUnit.Case
  alias Ecto.{InvalidChangesetError, NoResultsError}

  describe "a table with a composite primary key" do
    import UserHelpers

    test "should support a call to first/2" do
      result = CompositePrimaryKey.first()

      assert result ==
               "from c0 in CompositePrimaryKey, order_by: [asc: c0.part_one, asc: c0.part_two], limit: ^1"
    end

    test "should support a call to last/2" do
      result = CompositePrimaryKey.last()

      assert result ==
               "from c0 in CompositePrimaryKey, order_by: [desc: c0.part_one, desc: c0.part_two], limit: ^1"
    end
  end

  describe "a table with no primary key" do
    import UserHelpers

    test "should not permit a call to last/2" do
      assert_raise ArgumentError, fn ->
        NoPrimaryKey.last()
      end
    end

    test "should permit a call to last/2 if order_by provided" do
      result = NoPrimaryKey.last(1, order_by: :info)
      assert result == "from n0 in NoPrimaryKey, order_by: [desc: n0.info], limit: ^1"
    end

    test "should support a call to last/2 if order_by is provided with multiple keys" do
      result = NoPrimaryKey.last(1, order_by: [asc: :info, desc: :other_info])

      assert result ==
               "from n0 in NoPrimaryKey, order_by: [desc: n0.info, asc: n0.other_info], limit: ^1"
    end

    test "should not permit a call to first/2" do
      assert_raise ArgumentError, fn ->
        NoPrimaryKey.first()
      end
    end

    test "should permit a call to first/2 if order_by provided" do
      result = NoPrimaryKey.first(1, order_by: :info)
      assert result == "from n0 in NoPrimaryKey, order_by: [asc: n0.info], limit: ^1"
    end

    test "should raise an exception for fetch/2" do
      assert_raise ArgumentError, fn ->
        NoPrimaryKey.fetch([1, 2, 3])
      end

      assert_raise ArgumentError, fn ->
        NoPrimaryKey.fetch(1)
      end
    end

    test "should raise an exception for find/2" do
      assert_raise ArgumentError, fn ->
        NoPrimaryKey.find([1, 2, 3])
      end

      assert_raise ArgumentError, fn ->
        NoPrimaryKey.find(1)
      end
    end
  end

  describe "building queries via scope" do
    import UserHelpers
    import Ecto.Query, only: [from: 2]

    test "should return the correct query" do
      kw_result = i(UserSingle.scope(id: 1))
      assert kw_result == "from u0 in UserSingle, where: u0.id == ^1"

      map_result = i(UserSingle.scope(%{id: 1}))
      assert map_result == "from u0 in UserSingle, where: u0.id == ^1"
    end

    test "should build on a query successfully" do
      query = from(x in UserSingle, where: x.id == 1)
      result = query |> UserSingle.scope(org_id: 123) |> i()
      assert result == "from u0 in UserSingle, where: u0.id == 1, where: u0.org_id == ^123"
    end

    test "should build on a query successfully and run in a where" do
      query = from(x in UserSingle, where: x.id == 1)
      scoped = UserSingle.scope(query, org_id: 123)
      result = UserSingle.first(1, conditions: scoped)

      assert result ==
               "from u0 in UserSingle, where: u0.id == 1, where: u0.org_id == ^123, order_by: [asc: u0.id], limit: ^1"
    end
  end

  describe "aggregate functions should work" do
    test "when using empty count" do
      assert UserSingle.count() == "from u0 in UserSingle, select: count()"
    end
  end

  describe "querying records should work" do
    test "when using where" do
      assert UserSingle.where(id: 1) == ["from u0 in UserSingle, where: u0.id == ^1"]
    end

    test "when using where with a limit" do
      assert UserSingle.where([id: 1], lock: :for_update) == [
               "from u0 in UserSingle, where: u0.id == ^1, lock: \"FOR UPDATE\""
             ]
    end

    test "when using where with a map" do
      assert UserSingle.where(%{id: 1}) == ["from u0 in UserSingle, where: u0.id == ^1"]
    end

    test "when using where with limit keyword" do
      assert UserSingle.where(id: 1, limit: 2) == [
               "from u0 in UserSingle, where: u0.id == ^1, where: u0.limit == ^2"
             ]
    end

    test "when using find" do
      assert UserSingle.find(1) == "from u0 in UserSingle, where: u0.id in ^[1]"
      assert UserDouble.find([1, 2]) == ["from u0 in UserDouble, where: u0.id in ^[1, 2]", nil]

      assert_raise(NoResultsError, fn ->
        UserSingle.find([1, 2])
      end)

      assert_raise(NoResultsError, fn ->
        UserNone.find(1)
      end)
    end

    test "when using find_by" do
      assert UserSingle.find_by(id: 1) ==
               "from u0 in UserSingle, where: u0.id == ^1, limit: ^1"

      assert UserSingle.find_by(%{id: 2}) ==
               "from u0 in UserSingle, where: u0.id == ^2, limit: ^1"
    end

    test "when using find_or_create_by" do
      assert UserSingle.find_or_create_by(id: 1) ==
               {:ok, "from u0 in UserSingle, where: u0.id == ^1, limit: ^1"}

      assert UserNone.find_or_create_by(id: 2) == {:ok, %{id: 2}}
    end

    test "when using fetch" do
      assert UserSingle.fetch(1) == {:ok, "from u0 in UserSingle, where: u0.id in ^[1]"}

      assert UserDouble.fetch([1, 2]) ==
               {:ok, ["from u0 in UserDouble, where: u0.id in ^[1, 2]", nil]}

      assert UserSingle.fetch([1, 2]) == :error
      assert UserNone.fetch(1) == :error
    end

    test "when using exists" do
      refute UserNone.exists?(one: 1)
      assert UserSingle.exists?(one: 1)
    end
  end

  describe "updating records should work" do
    test "when calling update" do
      {:ok, us} = UserOK.update(%UserSingle{}, id: 1)
      assert us.changes == %{id: 1}

      {:error, nus} = UserError.update(%UserSingle{}, id: 1)
      assert nus.changes == %{id: 1}
    end

    test "when calling update!" do
      us = UserOK.update!(%UserSingle{}, id: 1)
      assert us.changes == %{id: 1}

      assert_raise(InvalidChangesetError, fn ->
        UserError.update!(%UserSingle{}, id: 1)
      end)
    end
  end

  describe "creating records should work" do
    test "when calling create" do
      {:ok, us} = UserOK.create(id: 1)
      assert us.changes == %{id: 1}

      {:error, nus} = UserError.create(id: 1)
      assert nus.changes == %{id: 1}
    end

    test "when calling create with a map" do
      {:ok, us} = UserOK.create(%{id: 1})
      assert us.changes == %{id: 1}
    end

    test "when calling create with a struct" do
      {:ok, us} = UserOK.create(%UserOK{id: 1})
      assert us.changes == %{id: 1}
    end

    test "when calling create!" do
      us = UserOK.create!(id: 1)
      assert us.changes == %{id: 1}

      assert_raise(InvalidChangesetError, fn ->
        UserError.create!(id: 1)
      end)
    end
  end

  describe "deleting records should work" do
    test "when calling delete" do
      assert {:ok, %UserOK{id: 1}} == UserOK.delete(%UserOK{id: 1})

      {:error, us} = UserError.delete(%UserOK{id: 1})
      assert us.data == %UserOK{id: 1}
    end

    test "when calling delete!" do
      us = UserOK.delete!(%UserOK{id: 1})
      assert us == %UserOK{id: 1}

      assert_raise(InvalidChangesetError, fn ->
        UserError.delete!(%UserError{id: 1})
      end)
    end
  end
end
