defmodule Endon do
  @moduledoc ~S"""
  Endon is an Elixir library that provides helper functions for [Ecto](https://hexdocs.pm/ecto/getting-started.html#content),
  with some inspiration from Ruby on Rails' [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html).

  It's designed to be used within a module that is an `Ecto.Schema` and provides helpful [functions](`Endon.Functions`).

  See the [overview](readme.html) and [features page](features.html) for examples.
  """

  alias Endon.Helpers

  defmacro __using__(opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:endon, :repo))

    quote bind_quoted: [repo: repo] do
      @repo repo

      @typedoc "Query conditions to use when selecting or updating records."
      @type where_conditions() :: Ecto.Query.t() | keyword() | map()

      @doc """
      Calculate the given aggregate over the given column.

      `conditions` are anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).
      """
      @spec aggregate(atom(), :avg | :count | :max | :min | :sum, where_conditions()) ::
              term() | nil
      def aggregate(column, aggregate, conditions \\ []),
        do: Helpers.aggregate(@repo, __MODULE__, column, aggregate, conditions)

      @doc """
      Fetches all entries from the data store matching the given query.

      Limit results to those matching these conditions.  Value can be
      anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).

      ## Options

        * `:order_by` - By default, orders by primary key ascending
        * `:preload` - A list of fields to preload, much like `c:Ecto.Repo.preload/3`
        * `:offset` - Number to offset by

      """
      @spec all(opts :: keyword()) :: list(Ecto.Schema.t())
      def all(opts \\ []),
        do: Helpers.all(@repo, __MODULE__, opts)

      @doc """
      Get the average of a given column.

      `conditions` are anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).
      """
      @spec avg(String.t() | atom(), where_conditions()) :: float() | nil
      def avg(column, conditions \\ []),
        do: aggregate(column, :avg, conditions)

      @doc """
      Get a count of all records matching the conditions.

      You can give an optional column;
      if none is specified, then it's the equivalent of a `select count(*)`.

      `conditions` are anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).
      """
      @spec count(atom() | nil, where_conditions()) :: integer()
      def count(column \\ nil, conditions \\ [])

      def count(nil, conditions), do: Helpers.count(@repo, __MODULE__, conditions)

      def count(column, conditions), do: aggregate(column, :count, conditions)

      @doc """
      Insert a new record into the data store.

      `params` can be either a `Keyword` list, a `Map` of attributes and values, or a struct
      of the same type being used to invoke `create/1`

      Returns `{:ok, struct}` if one is created, or `{:error, changeset}` if there is
      a validation error.
      """
      @spec create(Ecto.Schema.t() | keyword() | map()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
      def create(params),
        do: Helpers.create(@repo, __MODULE__, params)

      @doc """
      Insert a new record into the data store.

      `params` can be either a `Keyword` list, a `Map` of attributes and values, or a struct
      of the same type being used to invoke `create!/1`

      Returns the struct if created, or raises a `Ecto.InvalidChangesetError` if there was
      a validation error.
      """
      @spec create!(Ecto.Schema.t() | keyword() | map()) :: Ecto.Schema.t()
      def create!(params),
        do: Helpers.create!(@repo, __MODULE__, params)

      @doc """
      Delete a record in the data store.

      The `struct` must be a `t:Ecto.Schema.t/0` (your module that uses `Ecto.Schema`).

      Returns `{:ok, struct}` if the record is deleted, or `{:error, changeset}` if there is
      a validation error.
      """
      @spec delete(Ecto.Schema.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
      def delete(%{} = struct),
        do: Helpers.delete(@repo, __MODULE__, struct)

      @doc """
      Delete a record in the data store.

      The `struct` must be a `t:Ecto.Schema.t/0` (your module that uses `Ecto.Schema`).

      Returns the struct if it was deleted, or raises a `Ecto.InvalidChangesetError` if there was
      a validation error.
      """
      @spec delete!(Ecto.Schema.t()) :: Ecto.Schema.t()
      def delete!(%{} = struct),
        do: Helpers.delete!(@repo, __MODULE__, struct)

      @doc """
      Delete multiple records in the data store based on conditions.

      Delete all the records that match the given `conditions` (the same as for `where/2`).

      **Note:** If you don't supply any conditions, _all_ records will be deleted.

      It returns a tuple containing the number of entries and any returned result as second element.
      The second element is nil by default unless a select is supplied in the update query.

      ## Examples

          # this line using Ecto.Repo
          from(p in Post, where: p.user_id == 123) |> MyRepo.delete_all

          # is the same as this line in Endon
          Post.delete_where(user_id: 123)

      """
      @spec delete_where(where_conditions()) :: {integer(), nil | [term()]}
      def delete_where(conditions \\ []),
        do: Helpers.delete_where(@repo, __MODULE__, conditions)

      @doc """
      Checks if there exists an entry that matches the given query.

      `conditions` are the same as those accepted by `where/2`.
      """
      @spec exists?(where_conditions()) :: boolean()
      def exists?(conditions),
        do: Helpers.exists?(@repo, __MODULE__, conditions)

      @doc """
      Fetches one or more structs from the data store based on the primary key(s) given.

      If one primary key is given, then one struct will be returned (or `:error` if not found)

      If more than one primary key value is given in a list, then all of the structs with those ids
      will be returned (and `:error` will be returned if any one of the primary
      keys can't be found).

      Will raise an exception if the module doesn't have a primary key defined, or if it is a
      composite primary key.

      ## Options

        * `:preload` - A list of fields to preload, much like `c:Ecto.Repo.preload/3`

      """
      @spec fetch(integer() | list(integer()), keyword()) ::
              {:ok, list(Ecto.Schema.t())} | {:ok, Ecto.Schema.t()} | :error
      def fetch(module_or_ids, opts \\ [])

      # this is necessary to not break the implementation for the Access protocol
      def fetch(%{} = container, key) when is_atom(key),
        do: Map.fetch(container, key)

      def fetch(id_or_ids, opts),
        do: Helpers.fetch(@repo, __MODULE__, id_or_ids, opts)

      @doc """
      Fetches one or more structs from the data store based on the primary key(s) given.

      Much like `fetch/2`, except an error is raised if the record(s) can't be found.

      If one primary key is given, then one struct will be returned (or a `Ecto.NoResultsError`
      raised if a match isn't found).

      If more than one primary key is given in a list, then all of the structs with those ids
      will be returned (and a `Ecto.NoResultsError` will be raised if any one of the primary
      keys can't be found).

      Will raise an exception if the module doesn't have a primary key defined, or if it is a
      composite primary key.

      ## Options

        * `:preload` - A list of fields to preload, much like `c:Ecto.Repo.preload/3`

      """
      @spec find(integer() | list(integer()), keyword()) ::
              list(Ecto.Schema.t()) | Ecto.Schema.t()
      def find(id_or_ids, opts \\ []),
        do: Helpers.find(@repo, __MODULE__, id_or_ids, opts)

      @doc """
      Find a single record based on given conditions.

      If a record can't be found, then `nil` is returned.

      ## Options

        * `:preload` - A list of fields to preload, much like `c:Ecto.Repo.preload/3`

      """
      @spec find_by(where_conditions(), keyword()) :: Ecto.Schema.t() | nil
      def find_by(conditions, opts \\ []),
        do: Helpers.find_by(@repo, __MODULE__, conditions, opts)

      @doc """
      Find or create a record based on specific attributes values.

      Similar to `find_by`, except that if a record cannot be found with the given attributes
      then a new one will be created.

      Returns `{:ok, struct}` if one is found/created, or `{:error, changeset}` if there is
      a validation error.
      """
      @spec find_or_create_by(where_conditions()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
      def find_or_create_by(params),
        do: Helpers.find_or_create_by(@repo, __MODULE__, params)

      @doc """
      Get the first `count` records.

      If you ask for one thing (`count` of 1),
      you will get back the first record or `nil` if none are found.  If you ask for more
      than one thing (`count` > 1), you'll get back a list of 0 or more records.

      If no order is defined it will order by primary key ascending.

      ## Options

        * `:order_by` - By default, orders by primary key ascending
        * `:conditions` - Limit results to those matching these conditions.  Value can be
          anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).

      If there is no primary key for the table then `:order_by` must be provided.

      ## Examples

           # get the first 3 posts, will return a list
           posts = Post.first(3)

           # get the first post, will return one item (or nil if none found)
           post = Post.first()

           # get the first 3 posts by author id 1
           posts = Post.first(3, conditions: [author_id: 1])

      """
      @spec first(integer(), keyword()) :: [Ecto.Schema.t()] | Ecto.Schema.t() | nil
      def first(count \\ 1, opts \\ [])

      def first(count, opts) when is_integer(count),
        do: Helpers.first(@repo, __MODULE__, count, opts)

      @doc """
      Get the last `count` records.

      If you ask for one thing (`count` of 1),
      you will get back the last record or `nil` if none are found.  If you ask for more
      than one thing (`count` > 1), you'll get back a list of 0 or more records.

      If no order is defined it will order by primary key descending.

      ## Options

        * `:order_by` - By default, orders by primary key ascending, and takes the last `count`
          records.
        * `:conditions` - Limit results to those matching these conditions.  Value can be
          anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).

      If there is no primary key for the table then `:order_by` must be provided.

      ## Examples

           # get the last 3 posts, will return a list
           posts = Post.last(3)

           # get the last post, will return one item
           post = Post.last()

           # get the last 3 posts by author id 1
           posts = Post.last(3, conditions: [author_id: 1])

      """
      @spec last(integer(), keyword()) :: [Ecto.Schema.t()] | Ecto.Schema.t() | nil
      def last(count \\ 1, opts \\ [])

      def last(count, opts) when is_integer(count),
        do: Helpers.last(@repo, __MODULE__, count, opts)

      @doc """
      Get the maximum value of a given column.

      `conditions` are anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).
      """
      @spec max(String.t() | atom(), where_conditions()) :: number() | nil
      def max(column, conditions \\ []),
        do: aggregate(column, :max, conditions)

      @doc """
      Get the minimum value of a given column.

      `conditions` are anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).
      """
      @spec min(String.t() | atom(), where_conditions()) :: number() | nil
      def min(column, conditions \\ []),
        do: aggregate(column, :min, conditions)

      @doc """
      Take a query and add conditions (the same as `where/2` accepts).

      This will not actually run the query, so you will need
      to pass the result to `where/2` or `c:Ecto.Repo.all/2`/`c:Ecto.Repo.one/2`.

      For instance:

          existing_query = from x in Post
          Post.scope(existing_query, id: 1) |> Post.first()

      This is just a helpful function to make adding conditions easier to an existing query.
      """
      @spec scope(Ecto.Query.t() | module(), where_conditions()) :: Ecto.Query.t()
      def scope(query, conditions),
        do: Helpers.scope(query, conditions)

      @doc """
      Create a query with the given conditions (the same as `where/2` accepts).

      This will not actually run the query, so you will need
      to pass the result to `where/2` or `c:Ecto.Repo.all/2`/`c:Ecto.Repo.one/2`.

      For instance, this will just run one query to find a record with id 1 with name Bill.

          Post.scope(id: 1) |> Post.scope(name: 'Bill') |> Post.first()

      This is just a helpful function to make adding conditions easier to an existing `Ecto.Schema`
      """
      @spec scope(where_conditions()) :: Ecto.Query.t()
      def scope(conditions),
        do: scope(__MODULE__, conditions)

      @doc """
      Get the sum of a given column.

      `conditions` are anything accepted by `where/2` (including a `t:Ecto.Query.t/0`).
      """
      @spec sum(String.t() | atom(), where_conditions()) :: number() | nil
      def sum(column, conditions \\ []),
        do: aggregate(column, :sum, conditions)

      @doc """
      Update a record in the data store.

      The `struct` must be a `t:Ecto.Schema.t/0` (your module that uses `Ecto.Schema`).
      `params` can be either a `Keyword` list or `Map` of attributes and values.

      Returns `{:ok, struct}` if one is created, or `{:error, changeset}` if there is
      a validation error.
      """
      @spec update(Ecto.Schema.t(), keyword() | map()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
      def update(%{} = struct, params),
        do: Helpers.update(@repo, __MODULE__, struct, params)

      @doc """
      Update a record in the data store.

      The `struct` must be a `t:Ecto.Schema.t/0` (your module that uses `Ecto.Schema`).
      `params` can be either a `Keyword` list or `Map` of attributes and values.

      Returns the struct if it was updated, or raises a `Ecto.InvalidChangesetError` if there was
      a validation error.
      """
      @spec update!(Ecto.Schema.t(), keyword() | map()) :: Ecto.Schema.t()
      def update!(%{} = struct, params),
        do: Helpers.update!(@repo, __MODULE__, struct, params)

      @doc """
      Update multiple records in the data store based on conditions.

      Update all the records that match the given `conditions`, setting the given `params`
      as attributes.  `params` can be either a `Keyword` list or `Map` of attributes and values,
      and `conditions` is the same as for `where/2`.

      It returns a tuple containing the number of entries and any returned result as second element.
      The second element is nil by default unless a select is supplied in the update query.
      """
      @spec update_where(keyword() | map(), where_conditions()) :: {integer(), nil | [term()]}
      def update_where(params, conditions \\ []),
        do: Helpers.update_where(@repo, __MODULE__, params, conditions)

      @doc """
      Fetch all entries that match the given conditions.

      The conditions can be a `t:Ecto.Query.t/0` or a `t:Keyword.t/0`.

      ## Options

        * `:order_by` - By default, no sort order is set
        * `:preload` - A list of fields to preload, much like `c:Ecto.Repo.preload/3`
        * `:offset` - Number to offset by
        * `:limit` - Limit results to the given count

      ## Examples

          iex> User.where(id: 1)
          iex> User.where(name: "billy", age: 23)
          iex> User.where([name: "billy", age: 23], limit: 10, order_by: [desc: :id])
          iex> query = from u in User, where: u.id > 10
          iex> User.where(query, limit: 1)
      """
      @spec where(where_conditions(), keyword()) :: list(Ecto.Schema.t())
      def where(conditions, opts \\ []),
        do: Helpers.where(@repo, __MODULE__, conditions, opts)
    end
  end
end
