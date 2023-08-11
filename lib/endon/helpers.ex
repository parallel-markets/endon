defmodule Endon.Helpers do
  @moduledoc false
  import Ecto.Query, only: [from: 2]

  alias Ecto.{InvalidChangesetError, NoResultsError, Query}

  def all(repo, module, opts) do
    module
    |> add_opts(opts, [:order_by, :preload, :offset])
    |> repo.all()
  end

  def exists?(repo, module, conditions) do
    results = where(repo, module, conditions, limit: 1)
    length(results) == 1
  end

  def delete(repo, _module, struct),
    do: repo.delete(struct)

  def delete!(repo, module, struct) do
    case delete(repo, module, struct) do
      {:ok, result} ->
        result

      {:error, changeset} ->
        raise InvalidChangesetError, action: "delete!", changeset: changeset
    end
  end

  def delete_where(repo, module, conditions) do
    module
    |> add_where(conditions)
    |> repo.delete_all()
  end

  def find(repo, module, ids, opts) do
    case fetch(repo, module, ids, opts) do
      {:ok, result} ->
        result

      :error ->
        # if nothing was raised in the fetch, then we know there's a single
        # primary key defined, but we didn't get all the results we expected
        [pk] = module.__schema__(:primary_key)
        raise NoResultsError, queryable: add_where(module, [{pk, ids}])
    end
  end

  def fetch(repo, module, ids, opts) when is_list(ids) do
    case module.__schema__(:primary_key) do
      [] ->
        raise ArgumentError, message: "No primary key defined for #{module}"

      [pk] ->
        result = where(repo, module, [{pk, ids}], opts)
        if length(result) == length(ids), do: {:ok, result}, else: :error

      [_ | _] ->
        raise ArgumentError, message: "Composite primary key defined for #{module}"
    end
  end

  def fetch(repo, module, id, opts) do
    case fetch(repo, module, [id], opts) do
      {:ok, [result]} ->
        {:ok, result}

      :error ->
        :error
    end
  end

  def find_or_create_by(repo, module, conditions) do
    case do_find_or_create_by(repo, module, conditions) do
      {:ok, result} -> result
      other -> other
    end
  end

  # This will return one of:
  # {:ok, {:ok, record}} which means we were able to find/create
  # {:ok, {:error, changeset}} which means were didn't find but couldn't create
  # {:error, reason} which means there was an issue in the transaction
  defp do_find_or_create_by(repo, module, conditions) do
    repo.transaction(fn ->
      case where(repo, module, conditions, limit: 1) do
        [result] ->
          {:ok, result}

        [] ->
          create(repo, module, conditions)
      end
    end)
  end

  def find_by(repo, module, conditions, opts) do
    module
    |> add_where(conditions)
    |> add_opts([limit: 1] ++ opts, [:limit, :preload, :lock])
    |> repo.one()
  end

  def where(repo, module, conditions, opts) do
    module
    |> add_where(conditions)
    |> add_opts(opts, [:limit, :order_by, :offset, :preload, :lock])
    |> repo.all()
  end

  def count(repo, module, conditions) do
    query = add_where(module, conditions)
    cquery = from(r in query, select: count())
    repo.one(cquery)
  end

  def aggregate(repo, module, column, aggregate, conditions) do
    module
    |> add_where(conditions)
    |> repo.aggregate(aggregate, column)
  end

  def update(repo, module, struct, params) when is_list(params),
    do: update(repo, module, struct, Enum.into(params, %{}))

  def update(repo, module, struct, params) do
    struct
    |> changeset(params, module)
    |> repo.update()
  end

  def update!(repo, module, struct, params) do
    case update(repo, module, struct, params) do
      {:ok, result} ->
        result

      {:error, changeset} ->
        raise InvalidChangesetError, action: "update!", changeset: changeset
    end
  end

  def update_where(repo, module, params, conditions) do
    module
    |> add_where(conditions)
    |> repo.update_all(set: params)
  end

  def first(repo, module, count, opts) do
    {conditions, opts} = Keyword.pop(opts, :conditions, [])

    where_opts =
      opts
      |> Keyword.put(:limit, count)
      |> put_new_order_by_opt(module)

    unless Keyword.has_key?(where_opts, :order_by) do
      msg = "Cannot call first/2 without a primary key set or :order_by argument provided"
      raise ArgumentError, message: msg
    end

    result = where(repo, module, conditions, where_opts)
    if where_opts[:limit] == 1, do: first_or_nil(result), else: result
  end

  def last(repo, module, count, opts) do
    {conditions, opts} = Keyword.pop(opts, :conditions, [])

    where_opts =
      opts
      |> Keyword.put(:limit, count)
      |> put_new_order_by_opt(module)
      |> reverse_order_by_opt()

    unless Keyword.has_key?(where_opts, :order_by) do
      msg = "Cannot call last/2 without a primary key set or :order_by argument provided"
      raise ArgumentError, message: msg
    end

    result = where(repo, module, conditions, where_opts)
    if where_opts[:limit] == 1, do: first_or_nil(result), else: Enum.reverse(result)
  end

  def create(repo, module, %module{} = struct) do
    create(repo, module, Map.drop(struct, [:__meta__, :__struct__]))
  end

  def create(repo, module, params) when is_list(params) do
    create(repo, module, Enum.into(params, %{}))
  end

  def create(repo, module, params) when is_map(params) do
    module.__struct__
    |> changeset(params, module)
    |> repo.insert()
  end

  def create!(repo, module, params) do
    case create(repo, module, params) do
      {:ok, result} ->
        result

      {:error, changeset} ->
        raise InvalidChangesetError, action: "create!", changeset: changeset
    end
  end

  def scope(query, conditions),
    do: add_where(query, conditions)

  # private
  defp changeset(struct, attributes, module) do
    if Kernel.function_exported?(module, :changeset, 2) do
      module.changeset(struct, attributes)
    else
      Ecto.Changeset.change(struct, attributes)
    end
  end

  defp first_or_nil([]), do: nil
  defp first_or_nil([first | _]), do: first

  # Given an options keyword list - if :order_by is provided, do nothing. If
  # there is a primary key set for the module, use that as the :order_by.
  # If there is no :order_by provided and no primary key, do nothing.
  defp put_new_order_by_opt(opts, module) do
    case {Keyword.get(opts, :order_by), module.__schema__(:primary_key)} do
      {nil, []} ->
        # No order_by given, but we also don't have a primary key available
        opts

      {nil, pk} ->
        # No order_by was given, but we do have a primary key
        Keyword.put(opts, :order_by, pk)

      _ ->
        # An order_by was given
        opts
    end
  end

  # Reverse the order of all keys provided in the :order_by option
  # in the given keyword list.  If :order_by isn't provided, do nothing.
  defp reverse_order_by_opt(opts) do
    opts
    |> Keyword.get(:order_by, [])
    |> List.wrap()
    |> Enum.into([], fn
      {:asc, key} -> {:desc, key}
      {:desc, key} -> {:asc, key}
      key when is_atom(key) -> {:desc, key}
    end)
    |> case do
      [] -> opts
      order_by -> Keyword.put(opts, :order_by, order_by)
    end
  end

  defp add_opts(query, [], _allowed_opts), do: query

  defp add_opts(query, [{f, v} | rest], allowed_opts) do
    if f not in allowed_opts do
      raise ArgumentError, message: "Option :#{f} is not valid in this context"
    end

    query |> apply_opt(f, v) |> add_opts(rest, allowed_opts)
  end

  defp apply_opt(query, :order_by, order_by), do: Query.order_by(query, ^order_by)
  defp apply_opt(query, :limit, limit), do: Query.limit(query, ^limit)
  defp apply_opt(query, :preload, preload), do: Query.preload(query, ^preload)
  defp apply_opt(query, :offset, offset), do: Query.offset(query, ^offset)
  # for security reasons, locks must always be literal strings
  defp apply_opt(query, :lock, :for_update), do: Query.lock(query, "FOR UPDATE")

  defp add_where(query, []), do: query

  # this works because we only ever call add_where with a first argument
  # of the struct itself
  defp add_where(_query, %Ecto.Query{} = conditions), do: conditions

  defp add_where(query, params) when is_map(params),
    do: add_where(query, Enum.into(params, []))

  defp add_where(query, [{f, v} | rest]) when is_list(v) do
    query = from(x in query, where: field(x, ^f) in ^v)
    add_where(query, rest)
  end

  defp add_where(query, [{f, nil} | rest]) do
    query = from(x in query, where: is_nil(field(x, ^f)))
    add_where(query, rest)
  end

  defp add_where(query, [{f, v} | rest]) do
    query
    |> Query.where(^[{f, v}])
    |> add_where(rest)
  end
end
