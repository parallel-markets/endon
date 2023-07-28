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
    case where(repo, module, conditions, limit: 1) do
      [] ->
        false

      [_] ->
        true
    end
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
        pk = get_primary_key(module)
        raise NoResultsError, queryable: add_where(module, [{pk, ids}])
    end
  end

  def fetch(repo, module, ids, opts) when is_list(ids) do
    pk = get_primary_key(module)
    result = where(repo, module, [{pk, ids}], opts)
    if length(result) == length(ids), do: {:ok, result}, else: :error
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

  def stream_where(repo, module, conditions, opts) do
    pk = get_primary_key(module)
    start = Keyword.get(opts, :start, 0)
    finish = Keyword.get(opts, :finish)
    limit = Keyword.get(opts, :batch_size, 1000)

    new_opts = Keyword.drop(opts, [:start, :finish, :batch_size])
    basequery = module |> add_where(conditions) |> add_opts(new_opts, [:preload])

    query =
      if is_nil(finish) do
        from(x in basequery, limit: ^limit, order_by: [asc: ^pk])
      else
        from(x in basequery, where: field(x, ^pk) <= ^finish, limit: ^limit, order_by: [asc: ^pk])
      end

    initparams = %{
      pk: pk,
      repo: repo,
      start: start,
      query: query,
      more_possible: true,
      limit: limit
    }

    Stream.resource(fn -> initparams end, &stream_iter/1, & &1)
  end

  defp stream_iter(%{more_possible: false}), do: {:halt, nil}

  defp stream_iter(
         %{pk: pk, repo: repo, start: start, query: query, more_possible: true, limit: limit} =
           params
       ) do
    case repo.all(from(x in query, where: field(x, ^pk) >= ^start)) do
      [] ->
        {:halt, nil}

      results ->
        lastid = Map.get(hd(Enum.take(results, -1)), pk)
        {results, %{params | start: lastid + 1, more_possible: length(results) == limit}}
    end
  end

  def find_by(repo, module, conditions, opts) do
    module
    |> add_where(conditions)
    |> add_opts([limit: 1] ++ opts, [:limit, :preload])
    |> repo.one()
  end

  def where(repo, module, conditions, opts) do
    module
    |> add_where(conditions)
    |> add_opts(opts, [:limit, :order_by, :offset, :preload])
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
    where_opts = Keyword.put(opts, :limit, count)
    result = where(repo, module, conditions, where_opts)
    if where_opts[:limit] == 1, do: first_or_nil(result), else: result
  end

  def last(repo, module, count, opts) do
    {conditions, opts} = Keyword.pop(opts, :conditions, [])
    pk = get_primary_key(module)

    where_opts =
      [order_by: [desc: pk]]
      |> Keyword.merge(opts)
      |> Keyword.put(:limit, count)

    result = where(repo, module, conditions, where_opts)
    if where_opts[:limit] == 1, do: first_or_nil(result), else: result
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

  defp get_primary_key(module) do
    [pk] = module.__schema__(:primary_key)
    pk
  end
end
