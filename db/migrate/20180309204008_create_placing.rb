class CreatePlacings < ActiveRecord::Migration[5.0]
  def change
    create_table :placings do |t|
      t.integer :player_id
      t.integer :event_id
      t.integer :placing

      t.timestamps
    end
  end
end
