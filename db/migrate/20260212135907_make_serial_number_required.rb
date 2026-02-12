# decor/db/migrate/20260212135907_make_serial_number_required.rb - version 1.0
# Makes serial_number field required (not null) for computers table

class MakeSerialNumberRequired < ActiveRecord::Migration[8.1]
  def change
    change_column_null :computers, :serial_number, false
  end
end
