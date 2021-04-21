defmodule Bancoh.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Bancoh.Repo
  alias Bancoh.Accounts.User
  alias Bancoh.Transactions.Transfer

  @doc """
  Returns the list of transfers.

  ## Examples

      iex> list_transfers()
      [%Transfer{}, ...]

  """
  def list_transfers do
    Repo.all(Transfer)
  end

  @doc """
  Gets a single transfer.

  Raises `Ecto.NoResultsError` if the Transfer does not exist.

  ## Examples

      iex> get_transfer!(123)
      %Transfer{}

      iex> get_transfer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transfer!(id), do: Repo.get!(Transfer, id)

  @doc """
  Creates a transfer.

  ## Examples

      iex> create_transfer(%{field: value})
      {:ok, %Transfer{}}

      iex> create_transfer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transfer(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:transfer, Transfer.changeset(%Transfer{}, attrs))
    |> Multi.run(:receiver, increase_balance())
    |> Multi.run(:sender, decrease_balance())
    |> Repo.transaction()
  end  

  defp increase_balance(is_refund \\ false) do
    fn repo, %{transfer: transfer} ->
      User
      |> repo.get(if is_refund, do: transfer.sender_id, else: transfer.receiver_id)
      |> (fn user -> User.changeset(user, %{balance: user.balance + transfer.balance}) end).()
      |> repo.update()
    end
  end

  defp decrease_balance(is_refund \\ false) do
    fn repo, %{transfer: transfer} ->
      User
      |> repo.get(if is_refund, do: transfer.receiver_id, else: transfer.sender_id)
      |> (fn user -> User.changeset(user, %{balance: user.balance - transfer.balance}) end).()
      |> repo.update()
    end
  end

  @doc """
  Updates a transfer.

  ## Examples

      iex> update_transfer(transfer, %{field: new_value})
      {:ok, %Transfer{}}

      iex> update_transfer(transfer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transfer(%Transfer{} = transfer) do
    Multi.new()
    |> Multi.insert(:transfer, Transfer.refund_changeset(transfer, %{is_valid: false}))
    |> Multi.run(:receiver, increase_balance(true))
    |> Multi.run(:sender, decrease_balance(true))
    |> Repo.transaction()
  end

  @doc """
  Deletes a transfer.

  ## Examples

      iex> delete_transfer(transfer)
      {:ok, %Transfer{}}

      iex> delete_transfer(transfer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transfer(%Transfer{} = transfer) do
    Repo.delete(transfer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transfer changes.

  ## Examples

      iex> change_transfer(transfer)
      %Ecto.Changeset{data: %Transfer{}}

  """
  def change_transfer(%Transfer{} = transfer, attrs \\ %{}) do
    Transfer.changeset(transfer, attrs)
  end
end
