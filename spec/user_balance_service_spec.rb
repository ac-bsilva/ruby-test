require 'spec_helper'
require_relative '../lib/user_balance_service.rb'

describe UsersBalanceReport do

  it 'Given a non existent csv file
      Then it must raises a Errno::ENOENT' do

    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(Errno::ENOENT)

  end

  it 'Given a csv file
      When the id column is nil
      Then it must raises a TypeError' do

    allow(CSV).to receive(:foreach).and_yield([nil, 1000])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(TypeError)

  end

  it 'Given a csv file
      When the id column is a string
      Then it must raises a ArgumentError' do

    allow(CSV).to receive(:foreach).and_yield(["abc", 1000])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(ArgumentError)

  end

  it 'Given a csv file
      When the id column is a boolean
      Then it must raises a TypeError' do

    allow(CSV).to receive(:foreach).and_yield([true, 1000])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(TypeError)

  end

  it 'Given a csv file
      When the id column is bigger than integer
      Then it must raises a LocalJumpError' do

    allow(CSV).to receive(:foreach).and_yield([2147483647, 1000])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(LocalJumpError)

  end

  it 'Given a csv file
      When the balance column is nil
      Then it must raises a TypeError' do

    allow(CSV).to receive(:foreach).and_yield([341, nil])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(TypeError)

  end

  it 'Given a csv file
      When the balance column is a string
      Then it must raises a ArgumentError' do

    allow(CSV).to receive(:foreach).and_yield([341, "abc"])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(ArgumentError)

  end

  it 'Given a csv file
      When the balance column is a boolean
      Then it must raises a TypeError' do

    allow(CSV).to receive(:foreach).and_yield([341, true])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(TypeError)

  end

  it 'Given a csv file
      When the balance column is bigger than integer
      Then it must raises a LocalJumpError' do

    allow(CSV).to receive(:foreach).and_yield([341, 2147483647])
    expect{ UsersBalanceReport::parse("accounts") }.to raise_error(LocalJumpError)

  end

  it 'Given two csv files first containing users accounts and second users transactions
      Then must generate a new csv file with the user balance after conciliation' do

    allow(CSV).to receive(:foreach).with("accounts").and_yield([341,10000])
    allow(CSV).to receive(:foreach).with("transactions").and_yield([341,15000])
    UsersBalanceReport::generate "accounts", "transactions" do |map|
      expect(map).not_to be_empty
      expect(map[341].balance).to eq(25000)
    end

  end

  describe UsersBalanceReport::User do

    let(:user) {
      UsersBalanceReport::User.new(341, 10000)
    }

    it 'Given a user with positive balance
        When a credit transaction comes
        Then increases the current balance' do

      user + 10000
      expect(user.balance).to eq(20000)

    end

    it 'Given a user with positive balance
        When a debit transaction with value less than the current balance comes
        Then decreases the current balance by the amount of the transaction value
        and the balance remains positive' do

      user - 5000
      expect(user.balance).to eq(5000)

    end

    it 'Given a user with positive balance
        When a debit transaction with value equals to the current balance comes
        Then decreases the current balance by the amount of the transaction value
        and the balance remains positive' do

      user - 10000
      expect(user.balance).to eq(0)

    end

    it 'Given a user with positive balance
        When a debit transaction with value bigger than the current balance comes
        Then decreases the current balance by the amount of the transaction value
          plus 500 as charge for leaving the balance negative' do

      user - 10001
      expect(user.balance).to eq(-501)

    end

    it 'Given a user with negative balance
        When a debit transaction comes
        Then decreases the current balance by the amount of the transaction value
          plus 500 as charge for leaving the balance negative' do

      user - 10000
      user - 1
      expect(user.balance).to eq(-501)

    end

    it 'Given a user with negative balance
        When a credit transaction with value less than the current negative balance comes
        Then increases the current balance by the amount of the transaction value
          and the balance remains negative' do

      user - 10000
      user - 1
      user + 1
      expect(user.balance).to eq(-500)

    end

    it 'Given a user with negative balance
        When a credit transaction with value equals or bigger than the current negative balance comes
        Then increases the current balance by the amount of the transaction value
          and the balance turns to positive' do

      user - 10000
      user - 5000
      user + 5500
      expect(user.balance).to eq(0)

    end

  end

end
