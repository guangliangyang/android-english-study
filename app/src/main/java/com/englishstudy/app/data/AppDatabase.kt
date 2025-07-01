package com.englishstudy.app.data

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import android.content.Context

@Database(
    entities = [TextEntry::class, Sentence::class],
    version = 2,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun textEntryDao(): TextEntryDao
    abstract fun sentenceDao(): SentenceDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "english_study_database"
                )
                .allowMainThreadQueries() // Allow main thread queries for debugging
                .fallbackToDestructiveMigration() // For now, recreate database on schema changes
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}