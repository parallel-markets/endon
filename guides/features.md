# Features

## Schema Queries
By setting an application-wide (or schema module specific) `Ecto.Repo` variable, your code doesn't have to mention the repo over and over (see [here](../README.md#configuration) for setup instructions).

```elixir
# Regular Ecto
MyRepo.get_by(Post, title: "My post")

# Endon
Post.find_by(title: "My post")
```

## Find or Create By
Let's say you want to make a `Post` with a title, unless it already exists in which case you want to just retrieve the record.  Ecto doesn't make this easy, because you have to build your own transaction:

```elixir
MyRepo.transaction(fn ->
  Post
  |> MyRepo.get_by(Post, title: "My post")
  |> case do
    nil ->
      MyRepo.insert!(%Post{title: "My post"})
    post ->
      post
  end
end)
```

Endon makes it easy:

```elixir
Post.find_or_create_by(title: "My post")
```

## Easy Condiitions
All of the `Endon` functions that act as selects can either take a `Ecto.Query` or a list of equality conditions.  For instance, to see if any records exist with a given title:

```elixir
# Regular Ecto
query = from p in Post, where: p.title == "My post"
Repo.exists?(query)

# Endon
Post.exists?(title: "My post")
```

You can even pass in `Ecto.Query`s:
```elixir
query = from p in Post, where: p.like_count > 10
Post.exists?(query)
```

## Preloading
Endon makes preloading easy!

```elixir
# Regular Ecto
Post |> MyRepo.get_by(id: 1) |> MyRepo.preload(:comments)

# Endon
Post.find_by(id: 1, preload: comments)
```

## And more!
Want to get the first or last `n` records?  Easy:

```elixir
# Ecto
# There's no short equivalent in Ecto, Ecto.Query.last gives only 1 record

# Endon
Post.last(10)
Post.last(1, conditions: [author_id: 3])

# Ecto
# There's no short equivalent in Ecto, Ecot.Query.first gives only 1 record

# Endon
Post.first(3)
Post.first(1, conditions: [author_id: 3])
```

Want to get a bunch of records given their ids?

```elixir
# Ecto
MyRepo.all(from p in Post, where: p.id in [1,2,3])

# Endon
Post.find([1, 2, 3])
```
