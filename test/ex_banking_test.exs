defmodule ExBankingTest do
  use ExUnit.Case

  setup_all do
    ExBanking.create_user("user1")
    ExBanking.create_user("user2")
    :ok
  end

  describe "&create_user/1" do
    test "test to create new user when args is string" do
      ExBanking.create_user("newuser")
      refute Registry.lookup(Registry.Users, "newuser") == []
    end

    test "test to get error response when user already exists" do
      assert ExBanking.create_user("user1") == {:error, :user_already_exists}
    end

    test "test to get rerror response when args is not string" do
      assert ExBanking.create_user(:hello) == {:error, :wrong_arguments}
    end
  end

  describe "&deposit/1" do
    test "test to deposit money correctly" do
      assert {:ok, _balance} = ExBanking.deposit("user1", 5, "usd")
    end

    test "test to get error response when user does not exist" do
      assert ExBanking.deposit("random", 5, "usd") == {:error, :user_does_not_exist}
    end

    test "test to get error response when we give bad args" do
      assert ExBanking.deposit("user1", "5", "usd") == {:error, :wrong_arguments}
    end

    test "test to get error response when there is too many requests" do
      ExBanking.create_user("deposit")

      error_count =
        1..100
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.deposit("deposit", 5, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_user} end)

      assert error_count >= 1
    end
  end

  describe "&withdraw/1" do
    test "test to withdraw money correctly" do
      ExBanking.deposit("user2", 10, "usd")
      assert {:ok, _balance} = ExBanking.withdraw("user2", 5, "usd")
    end

    test "test to withdraw more money than the user actually have" do
      assert ExBanking.withdraw("user1", 500, "usd") == {:error, :not_enough_money}
    end

    test "test to get error response when user does not exist" do
      assert ExBanking.withdraw("random", 5, "usd") == {:error, :user_does_not_exist}
    end

    test "test to get error response when we give bad args" do
      assert ExBanking.withdraw("user1", "5", "usd") == {:error, :wrong_arguments}
    end

    test "test to get error response when there is too many requests" do
      ExBanking.create_user("withdraw")

      error_count =
        1..100
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.withdraw("withdraw", 5, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_user} end)

      assert error_count >= 1
    end
  end

  describe "&get_balance/1" do
    test "test to get balance correctly" do
      assert {:ok, _balance} = ExBanking.get_balance("user1", "usd")
    end

    test "test to get error response when user does not exist" do
      assert ExBanking.get_balance("random", "usd") == {:error, :user_does_not_exist}
    end

    test "test to get error response when we give bad args" do
      assert ExBanking.get_balance("user1", :usd) == {:error, :wrong_arguments}
    end

    test "test to get error response when there is too many requests" do
      ExBanking.create_user("balance")

      error_count =
        1..100
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.get_balance("balance", "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_user} end)

      assert error_count >= 1
    end
  end

  describe "&send/1" do
    test "test to send money correctly" do
      ExBanking.deposit("user1", 5, "usd")
      assert {:ok, _from, _to} = ExBanking.send("user1", "user2", 5, "usd")
    end

    test "test to get error response when from user does not exist" do
      assert ExBanking.send("random", "user2", 5, "usd") == {:error, :sender_does_not_exist}
    end

    test "test to get error response when to user does not exist" do
      ExBanking.deposit("user1", 5, "usd")
      assert ExBanking.send("user1", "to", 5, "usd") == {:error, :receiver_does_not_exist}
    end

    test "test to get error response when we give bad args" do
      assert ExBanking.send("user1", "user2", "5", :usd) == {:error, :wrong_arguments}
    end

    test "test to get error response when there is too many requests for sender" do
      ExBanking.create_user("sender")
      ExBanking.create_user("receiver")

      error_count =
        1..100
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.send("sender", "receiver", 5, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_sender} end)

      assert error_count >= 1
    end

    test "test to get error response when there is too many requests for receiver" do
      ExBanking.create_user("sender")
      ExBanking.create_user("receiver")
      ExBanking.deposit("sender", 1000, "usd")

      error_count =
        1..100
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.send("sender", "receiver", 5, "usd") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn result -> result !== {:error, :too_many_requests_to_receiver} end)

      assert error_count >= 1
    end
  end
end
