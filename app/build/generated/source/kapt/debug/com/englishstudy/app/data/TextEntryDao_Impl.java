package com.englishstudy.app.data;

import android.database.Cursor;
import androidx.lifecycle.LiveData;
import androidx.room.EntityDeletionOrUpdateAdapter;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;

@SuppressWarnings({"unchecked", "deprecation"})
public final class TextEntryDao_Impl implements TextEntryDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<TextEntry> __insertionAdapterOfTextEntry;

  private final EntityDeletionOrUpdateAdapter<TextEntry> __deletionAdapterOfTextEntry;

  private final EntityDeletionOrUpdateAdapter<TextEntry> __updateAdapterOfTextEntry;

  public TextEntryDao_Impl(RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfTextEntry = new EntityInsertionAdapter<TextEntry>(__db) {
      @Override
      public String createQuery() {
        return "INSERT OR ABORT INTO `text_entries` (`id`,`title`,`content`,`audioFilePath`,`wordCount`,`estimatedDuration`,`createdAt`) VALUES (nullif(?, 0),?,?,?,?,?,?)";
      }

      @Override
      public void bind(SupportSQLiteStatement stmt, TextEntry value) {
        stmt.bindLong(1, value.getId());
        if (value.getTitle() == null) {
          stmt.bindNull(2);
        } else {
          stmt.bindString(2, value.getTitle());
        }
        if (value.getContent() == null) {
          stmt.bindNull(3);
        } else {
          stmt.bindString(3, value.getContent());
        }
        if (value.getAudioFilePath() == null) {
          stmt.bindNull(4);
        } else {
          stmt.bindString(4, value.getAudioFilePath());
        }
        stmt.bindLong(5, value.getWordCount());
        if (value.getEstimatedDuration() == null) {
          stmt.bindNull(6);
        } else {
          stmt.bindString(6, value.getEstimatedDuration());
        }
        stmt.bindLong(7, value.getCreatedAt());
      }
    };
    this.__deletionAdapterOfTextEntry = new EntityDeletionOrUpdateAdapter<TextEntry>(__db) {
      @Override
      public String createQuery() {
        return "DELETE FROM `text_entries` WHERE `id` = ?";
      }

      @Override
      public void bind(SupportSQLiteStatement stmt, TextEntry value) {
        stmt.bindLong(1, value.getId());
      }
    };
    this.__updateAdapterOfTextEntry = new EntityDeletionOrUpdateAdapter<TextEntry>(__db) {
      @Override
      public String createQuery() {
        return "UPDATE OR ABORT `text_entries` SET `id` = ?,`title` = ?,`content` = ?,`audioFilePath` = ?,`wordCount` = ?,`estimatedDuration` = ?,`createdAt` = ? WHERE `id` = ?";
      }

      @Override
      public void bind(SupportSQLiteStatement stmt, TextEntry value) {
        stmt.bindLong(1, value.getId());
        if (value.getTitle() == null) {
          stmt.bindNull(2);
        } else {
          stmt.bindString(2, value.getTitle());
        }
        if (value.getContent() == null) {
          stmt.bindNull(3);
        } else {
          stmt.bindString(3, value.getContent());
        }
        if (value.getAudioFilePath() == null) {
          stmt.bindNull(4);
        } else {
          stmt.bindString(4, value.getAudioFilePath());
        }
        stmt.bindLong(5, value.getWordCount());
        if (value.getEstimatedDuration() == null) {
          stmt.bindNull(6);
        } else {
          stmt.bindString(6, value.getEstimatedDuration());
        }
        stmt.bindLong(7, value.getCreatedAt());
        stmt.bindLong(8, value.getId());
      }
    };
  }

  @Override
  public long insertEntry(final TextEntry entry) {
    __db.assertNotSuspendingTransaction();
    __db.beginTransaction();
    try {
      long _result = __insertionAdapterOfTextEntry.insertAndReturnId(entry);
      __db.setTransactionSuccessful();
      return _result;
    } finally {
      __db.endTransaction();
    }
  }

  @Override
  public int deleteEntry(final TextEntry entry) {
    __db.assertNotSuspendingTransaction();
    int _total = 0;
    __db.beginTransaction();
    try {
      _total +=__deletionAdapterOfTextEntry.handle(entry);
      __db.setTransactionSuccessful();
      return _total;
    } finally {
      __db.endTransaction();
    }
  }

  @Override
  public int updateEntry(final TextEntry entry) {
    __db.assertNotSuspendingTransaction();
    int _total = 0;
    __db.beginTransaction();
    try {
      _total +=__updateAdapterOfTextEntry.handle(entry);
      __db.setTransactionSuccessful();
      return _total;
    } finally {
      __db.endTransaction();
    }
  }

  @Override
  public LiveData<List<TextEntry>> getAllEntries() {
    final String _sql = "SELECT * FROM text_entries ORDER BY createdAt DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    return __db.getInvalidationTracker().createLiveData(new String[]{"text_entries"}, false, new Callable<List<TextEntry>>() {
      @Override
      public List<TextEntry> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
          final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
          final int _cursorIndexOfWordCount = CursorUtil.getColumnIndexOrThrow(_cursor, "wordCount");
          final int _cursorIndexOfEstimatedDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "estimatedDuration");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<TextEntry> _result = new ArrayList<TextEntry>(_cursor.getCount());
          while(_cursor.moveToNext()) {
            final TextEntry _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpTitle;
            if (_cursor.isNull(_cursorIndexOfTitle)) {
              _tmpTitle = null;
            } else {
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            }
            final String _tmpContent;
            if (_cursor.isNull(_cursorIndexOfContent)) {
              _tmpContent = null;
            } else {
              _tmpContent = _cursor.getString(_cursorIndexOfContent);
            }
            final String _tmpAudioFilePath;
            if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
              _tmpAudioFilePath = null;
            } else {
              _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
            }
            final int _tmpWordCount;
            _tmpWordCount = _cursor.getInt(_cursorIndexOfWordCount);
            final String _tmpEstimatedDuration;
            if (_cursor.isNull(_cursorIndexOfEstimatedDuration)) {
              _tmpEstimatedDuration = null;
            } else {
              _tmpEstimatedDuration = _cursor.getString(_cursorIndexOfEstimatedDuration);
            }
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _item = new TextEntry(_tmpId,_tmpTitle,_tmpContent,_tmpAudioFilePath,_tmpWordCount,_tmpEstimatedDuration,_tmpCreatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public List<TextEntry> getAllEntriesSync() {
    final String _sql = "SELECT * FROM text_entries ORDER BY createdAt DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 0);
    __db.assertNotSuspendingTransaction();
    final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
    try {
      final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
      final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
      final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
      final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
      final int _cursorIndexOfWordCount = CursorUtil.getColumnIndexOrThrow(_cursor, "wordCount");
      final int _cursorIndexOfEstimatedDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "estimatedDuration");
      final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
      final List<TextEntry> _result = new ArrayList<TextEntry>(_cursor.getCount());
      while(_cursor.moveToNext()) {
        final TextEntry _item;
        final long _tmpId;
        _tmpId = _cursor.getLong(_cursorIndexOfId);
        final String _tmpTitle;
        if (_cursor.isNull(_cursorIndexOfTitle)) {
          _tmpTitle = null;
        } else {
          _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
        }
        final String _tmpContent;
        if (_cursor.isNull(_cursorIndexOfContent)) {
          _tmpContent = null;
        } else {
          _tmpContent = _cursor.getString(_cursorIndexOfContent);
        }
        final String _tmpAudioFilePath;
        if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
          _tmpAudioFilePath = null;
        } else {
          _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
        }
        final int _tmpWordCount;
        _tmpWordCount = _cursor.getInt(_cursorIndexOfWordCount);
        final String _tmpEstimatedDuration;
        if (_cursor.isNull(_cursorIndexOfEstimatedDuration)) {
          _tmpEstimatedDuration = null;
        } else {
          _tmpEstimatedDuration = _cursor.getString(_cursorIndexOfEstimatedDuration);
        }
        final long _tmpCreatedAt;
        _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
        _item = new TextEntry(_tmpId,_tmpTitle,_tmpContent,_tmpAudioFilePath,_tmpWordCount,_tmpEstimatedDuration,_tmpCreatedAt);
        _result.add(_item);
      }
      return _result;
    } finally {
      _cursor.close();
      _statement.release();
    }
  }

  @Override
  public LiveData<List<TextEntry>> searchEntries(final String searchQuery) {
    final String _sql = "SELECT * FROM text_entries WHERE title LIKE '%' || ? || '%' OR content LIKE '%' || ? || '%' ORDER BY createdAt DESC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 2);
    int _argIndex = 1;
    if (searchQuery == null) {
      _statement.bindNull(_argIndex);
    } else {
      _statement.bindString(_argIndex, searchQuery);
    }
    _argIndex = 2;
    if (searchQuery == null) {
      _statement.bindNull(_argIndex);
    } else {
      _statement.bindString(_argIndex, searchQuery);
    }
    return __db.getInvalidationTracker().createLiveData(new String[]{"text_entries"}, false, new Callable<List<TextEntry>>() {
      @Override
      public List<TextEntry> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
          final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
          final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
          final int _cursorIndexOfWordCount = CursorUtil.getColumnIndexOrThrow(_cursor, "wordCount");
          final int _cursorIndexOfEstimatedDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "estimatedDuration");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<TextEntry> _result = new ArrayList<TextEntry>(_cursor.getCount());
          while(_cursor.moveToNext()) {
            final TextEntry _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final String _tmpTitle;
            if (_cursor.isNull(_cursorIndexOfTitle)) {
              _tmpTitle = null;
            } else {
              _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
            }
            final String _tmpContent;
            if (_cursor.isNull(_cursorIndexOfContent)) {
              _tmpContent = null;
            } else {
              _tmpContent = _cursor.getString(_cursorIndexOfContent);
            }
            final String _tmpAudioFilePath;
            if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
              _tmpAudioFilePath = null;
            } else {
              _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
            }
            final int _tmpWordCount;
            _tmpWordCount = _cursor.getInt(_cursorIndexOfWordCount);
            final String _tmpEstimatedDuration;
            if (_cursor.isNull(_cursorIndexOfEstimatedDuration)) {
              _tmpEstimatedDuration = null;
            } else {
              _tmpEstimatedDuration = _cursor.getString(_cursorIndexOfEstimatedDuration);
            }
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _item = new TextEntry(_tmpId,_tmpTitle,_tmpContent,_tmpAudioFilePath,_tmpWordCount,_tmpEstimatedDuration,_tmpCreatedAt);
            _result.add(_item);
          }
          return _result;
        } finally {
          _cursor.close();
        }
      }

      @Override
      protected void finalize() {
        _statement.release();
      }
    });
  }

  @Override
  public TextEntry getEntryById(final long id) {
    final String _sql = "SELECT * FROM text_entries WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, id);
    __db.assertNotSuspendingTransaction();
    final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
    try {
      final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
      final int _cursorIndexOfTitle = CursorUtil.getColumnIndexOrThrow(_cursor, "title");
      final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
      final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
      final int _cursorIndexOfWordCount = CursorUtil.getColumnIndexOrThrow(_cursor, "wordCount");
      final int _cursorIndexOfEstimatedDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "estimatedDuration");
      final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
      final TextEntry _result;
      if(_cursor.moveToFirst()) {
        final long _tmpId;
        _tmpId = _cursor.getLong(_cursorIndexOfId);
        final String _tmpTitle;
        if (_cursor.isNull(_cursorIndexOfTitle)) {
          _tmpTitle = null;
        } else {
          _tmpTitle = _cursor.getString(_cursorIndexOfTitle);
        }
        final String _tmpContent;
        if (_cursor.isNull(_cursorIndexOfContent)) {
          _tmpContent = null;
        } else {
          _tmpContent = _cursor.getString(_cursorIndexOfContent);
        }
        final String _tmpAudioFilePath;
        if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
          _tmpAudioFilePath = null;
        } else {
          _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
        }
        final int _tmpWordCount;
        _tmpWordCount = _cursor.getInt(_cursorIndexOfWordCount);
        final String _tmpEstimatedDuration;
        if (_cursor.isNull(_cursorIndexOfEstimatedDuration)) {
          _tmpEstimatedDuration = null;
        } else {
          _tmpEstimatedDuration = _cursor.getString(_cursorIndexOfEstimatedDuration);
        }
        final long _tmpCreatedAt;
        _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
        _result = new TextEntry(_tmpId,_tmpTitle,_tmpContent,_tmpAudioFilePath,_tmpWordCount,_tmpEstimatedDuration,_tmpCreatedAt);
      } else {
        _result = null;
      }
      return _result;
    } finally {
      _cursor.close();
      _statement.release();
    }
  }

  public static List<Class<?>> getRequiredConverters() {
    return Collections.emptyList();
  }
}
