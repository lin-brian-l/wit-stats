class CreatePlayers < ActiveRecord::Migration[5.0]
  def change
    create_table :players do |t|
      t.string :gamer_tag, { null: false }

      t.timestamps
    end
  end
end