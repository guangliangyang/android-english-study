package com.englishstudy.app.data;

import androidx.room.DatabaseConfiguration;
import androidx.room.InvalidationTracker;
import androidx.room.RoomOpenHelper;
import androidx.room.RoomOpenHelper.Delegate;
import androidx.room.RoomOpenHelper.ValidationResult;
import androidx.room.util.DBUtil;
import androidx.room.util.TableInfo;
import androidx.room.util.TableInfo.Column;
import androidx.room.util.TableInfo.ForeignKey;
import androidx.room.util.TableInfo.Index;
import androidx.sqlite.db.SupportSQLiteDatabase;
import androidx.sqlite.db.SupportSQLiteOpenHelper;
import androidx.sqlite.db.SupportSQLiteOpenHelper.Callback;
import androidx.sqlite.db.SupportSQLiteOpenHelper.Configuration;
import java.lang.Class;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@SuppressWarnings({"unchecked", "deprecation"})
public final class AppDatabase_Impl extends AppDatabase {
  private volatile TextEntryDao _textEntryDao;

  private volatile SentenceDao _sentenceDao;

  @Override
  protected SupportSQLiteOpenHelper createOpenHelper(DatabaseConfiguration configuration) {
    final SupportSQLiteOpenHelper.Callback _openCallback = new RoomOpenHelper(configuration, new RoomOpenHelper.Delegate(2) {
      @Override
      public void createAllTables(SupportSQLiteDatabase _db) {
        _db.execSQL("CREATE TABLE IF NOT EXISTS `text_entries` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `title` TEXT NOT NULL, `content` TEXT NOT NULL, `audioFilePath` TEXT, `wordCount` INTEGER NOT NULL, `estimatedDuration` TEXT, `createdAt` INTEGER NOT NULL)");
        _db.execSQL("CREATE TABLE IF NOT EXISTS `sentences` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `textEntryId` INTEGER NOT NULL, `content` TEXT NOT NULL, `orderIndex` INTEGER NOT NULL, `audioFilePath` TEXT, `duration` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, FOREIGN KEY(`textEntryId`) REFERENCES `text_entries`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )");
        _db.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)");
        _db.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, 'efe7238691f4e9b14e4a8fdf9cbde053')");
      }

      @Override
      public void dropAllTables(SupportSQLiteDatabase _db) {
        _db.execSQL("DROP TABLE IF EXISTS `text_entries`");
        _db.execSQL("DROP TABLE IF EXISTS `sentences`");
        if (mCallbacks != null) {
          for (int _i = 0, _size = mCallbacks.size(); _i < _size; _i++) {
            mCallbacks.get(_i).onDestructiveMigration(_db);
          }
        }
      }

      @Override
      protected void onCreate(SupportSQLiteDatabase _db) {
        if (mCallbacks != null) {
          for (int _i = 0, _size = mCallbacks.size(); _i < _size; _i++) {
            mCallbacks.get(_i).onCreate(_db);
          }
        }
      }

      @Override
      public void onOpen(SupportSQLiteDatabase _db) {
        mDatabase = _db;
        _db.execSQL("PRAGMA foreign_keys = ON");
        internalInitInvalidationTracker(_db);
        if (mCallbacks != null) {
          for (int _i = 0, _size = mCallbacks.size(); _i < _size; _i++) {
            mCallbacks.get(_i).onOpen(_db);
          }
        }
      }

      @Override
      public void onPreMigrate(SupportSQLiteDatabase _db) {
        DBUtil.dropFtsSyncTriggers(_db);
      }

      @Override
      public void onPostMigrate(SupportSQLiteDatabase _db) {
      }

      @Override
      protected RoomOpenHelper.ValidationResult onValidateSchema(SupportSQLiteDatabase _db) {
        final HashMap<String, TableInfo.Column> _columnsTextEntries = new HashMap<String, TableInfo.Column>(7);
        _columnsTextEntries.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTextEntries.put("title", new TableInfo.Column("title", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTextEntries.put("content", new TableInfo.Column("content", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTextEntries.put("audioFilePath", new TableInfo.Column("audioFilePath", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTextEntries.put("wordCount", new TableInfo.Column("wordCount", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTextEntries.put("estimatedDuration", new TableInfo.Column("estimatedDuration", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsTextEntries.put("createdAt", new TableInfo.Column("createdAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysTextEntries = new HashSet<TableInfo.ForeignKey>(0);
        final HashSet<TableInfo.Index> _indicesTextEntries = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoTextEntries = new TableInfo("text_entries", _columnsTextEntries, _foreignKeysTextEntries, _indicesTextEntries);
        final TableInfo _existingTextEntries = TableInfo.read(_db, "text_entries");
        if (! _infoTextEntries.equals(_existingTextEntries)) {
          return new RoomOpenHelper.ValidationResult(false, "text_entries(com.englishstudy.app.data.TextEntry).\n"
                  + " Expected:\n" + _infoTextEntries + "\n"
                  + " Found:\n" + _existingTextEntries);
        }
        final HashMap<String, TableInfo.Column> _columnsSentences = new HashMap<String, TableInfo.Column>(7);
        _columnsSentences.put("id", new TableInfo.Column("id", "INTEGER", true, 1, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSentences.put("textEntryId", new TableInfo.Column("textEntryId", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSentences.put("content", new TableInfo.Column("content", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSentences.put("orderIndex", new TableInfo.Column("orderIndex", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSentences.put("audioFilePath", new TableInfo.Column("audioFilePath", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSentences.put("duration", new TableInfo.Column("duration", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        _columnsSentences.put("createdAt", new TableInfo.Column("createdAt", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY));
        final HashSet<TableInfo.ForeignKey> _foreignKeysSentences = new HashSet<TableInfo.ForeignKey>(1);
        _foreignKeysSentences.add(new TableInfo.ForeignKey("text_entries", "CASCADE", "NO ACTION",Arrays.asList("textEntryId"), Arrays.asList("id")));
        final HashSet<TableInfo.Index> _indicesSentences = new HashSet<TableInfo.Index>(0);
        final TableInfo _infoSentences = new TableInfo("sentences", _columnsSentences, _foreignKeysSentences, _indicesSentences);
        final TableInfo _existingSentences = TableInfo.read(_db, "sentences");
        if (! _infoSentences.equals(_existingSentences)) {
          return new RoomOpenHelper.ValidationResult(false, "sentences(com.englishstudy.app.data.Sentence).\n"
                  + " Expected:\n" + _infoSentences + "\n"
                  + " Found:\n" + _existingSentences);
        }
        return new RoomOpenHelper.ValidationResult(true, null);
      }
    }, "efe7238691f4e9b14e4a8fdf9cbde053", "ac4db67cf0186bd547d0af95931302f1");
    final SupportSQLiteOpenHelper.Configuration _sqliteConfig = SupportSQLiteOpenHelper.Configuration.builder(configuration.context)
        .name(configuration.name)
        .callback(_openCallback)
        .build();
    final SupportSQLiteOpenHelper _helper = configuration.sqliteOpenHelperFactory.create(_sqliteConfig);
    return _helper;
  }

  @Override
  protected InvalidationTracker createInvalidationTracker() {
    final HashMap<String, String> _shadowTablesMap = new HashMap<String, String>(0);
    HashMap<String, Set<String>> _viewTables = new HashMap<String, Set<String>>(0);
    return new InvalidationTracker(this, _shadowTablesMap, _viewTables, "text_entries","sentences");
  }

  @Override
  public void clearAllTables() {
    super.assertNotMainThread();
    final SupportSQLiteDatabase _db = super.getOpenHelper().getWritableDatabase();
    boolean _supportsDeferForeignKeys = android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP;
    try {
      if (!_supportsDeferForeignKeys) {
        _db.execSQL("PRAGMA foreign_keys = FALSE");
      }
      super.beginTransaction();
      if (_supportsDeferForeignKeys) {
        _db.execSQL("PRAGMA defer_foreign_keys = TRUE");
      }
      _db.execSQL("DELETE FROM `text_entries`");
      _db.execSQL("DELETE FROM `sentences`");
      super.setTransactionSuccessful();
    } finally {
      super.endTransaction();
      if (!_supportsDeferForeignKeys) {
        _db.execSQL("PRAGMA foreign_keys = TRUE");
      }
      _db.query("PRAGMA wal_checkpoint(FULL)").close();
      if (!_db.inTransaction()) {
        _db.execSQL("VACUUM");
      }
    }
  }

  @Override
  protected Map<Class<?>, List<Class<?>>> getRequiredTypeConverters() {
    final HashMap<Class<?>, List<Class<?>>> _typeConvertersMap = new HashMap<Class<?>, List<Class<?>>>();
    _typeConvertersMap.put(TextEntryDao.class, TextEntryDao_Impl.getRequiredConverters());
    _typeConvertersMap.put(SentenceDao.class, SentenceDao_Impl.getRequiredConverters());
    return _typeConvertersMap;
  }

  @Override
  public TextEntryDao textEntryDao() {
    if (_textEntryDao != null) {
      return _textEntryDao;
    } else {
      synchronized(this) {
        if(_textEntryDao == null) {
          _textEntryDao = new TextEntryDao_Impl(this);
        }
        return _textEntryDao;
      }
    }
  }

  @Override
  public SentenceDao sentenceDao() {
    if (_sentenceDao != null) {
      return _sentenceDao;
    } else {
      synchronized(this) {
        if(_sentenceDao == null) {
          _sentenceDao = new SentenceDao_Impl(this);
        }
        return _sentenceDao;
      }
    }
  }
}
