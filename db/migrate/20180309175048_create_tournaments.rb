class CreateTournaments < ActiveRecord::Migration[5.0]
  def change
    create_table :tournaments do |t|
      t.string :name, { null: false }
      t.date :date

      t.timestamps
    end
  end
end
