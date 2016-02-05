require "csv"

module UsersBalanceReport

  class User
    attr_accessor :id, :balance

    def initialize( id, balance )
      @id = id
      @balance = balance
    end

    def +( value )
      @balance += value
      @balance -= 500 if @balance < 0 && value < 0
    end

    def -( value )
      @balance -= value
      @balance -= 500 if @balance < 0
    end

    def to_a
      [ @id, @balance ]
    end

  end

  def self.generate( users, transactions )

    self.parse_users( users ) do |accounts|
      self.parse_transactions( accounts, transactions ) do |balance|
        if block_given?
          yield balance
        else
          balance.each do |k,v|
            puts v.to_a.to_csv
          end
        end
      end
    end

  end

  def self.parse( file )
    CSV.foreach( file ) do |row|
      validate row
      yield row
    end
  end

  def self.parse_users( path )
    map = Hash.new
    self.parse( path ) do |row|
      map[ row[0] ] = User.new( row[0], row[1].to_i )
    end
    yield map
  end

  def self.parse_transactions( map, path )
    self.parse( path ) do |row|
      next unless map.has_key?(row[0])
      map[row[0]] + row[1].to_i
    end
    yield map
  end

  private
    def self.validate( row )
      Integer(row[0])
      Integer(row[1])
    end
end
