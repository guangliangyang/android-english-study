package com.englishstudy.app.data;

import android.database.Cursor;
import androidx.lifecycle.LiveData;
import androidx.room.EntityDeletionOrUpdateAdapter;
import androidx.room.EntityInsertionAdapter;
import androidx.room.RoomDatabase;
import androidx.room.RoomSQLiteQuery;
import androidx.room.SharedSQLiteStatement;
import androidx.room.util.CursorUtil;
import androidx.room.util.DBUtil;
import androidx.sqlite.db.SupportSQLiteStatement;
import java.lang.Class;
import java.lang.Exception;
import java.lang.Long;
import java.lang.Override;
import java.lang.String;
import java.lang.SuppressWarnings;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;

@SuppressWarnings({"unchecked", "deprecation"})
public final class SentenceDao_Impl implements SentenceDao {
  private final RoomDatabase __db;

  private final EntityInsertionAdapter<Sentence> __insertionAdapterOfSentence;

  private final EntityDeletionOrUpdateAdapter<Sentence> __deletionAdapterOfSentence;

  private final EntityDeletionOrUpdateAdapter<Sentence> __updateAdapterOfSentence;

  private final SharedSQLiteStatement __preparedStmtOfDeleteSentencesByTextEntryId;

  public SentenceDao_Impl(RoomDatabase __db) {
    this.__db = __db;
    this.__insertionAdapterOfSentence = new EntityInsertionAdapter<Sentence>(__db) {
      @Override
      public String createQuery() {
        return "INSERT OR ABORT INTO `sentences` (`id`,`textEntryId`,`content`,`orderIndex`,`audioFilePath`,`duration`,`createdAt`) VALUES (nullif(?, 0),?,?,?,?,?,?)";
      }

      @Override
      public void bind(SupportSQLiteStatement stmt, Sentence value) {
        stmt.bindLong(1, value.getId());
        stmt.bindLong(2, value.getTextEntryId());
        if (value.getContent() == null) {
          stmt.bindNull(3);
        } else {
          stmt.bindString(3, value.getContent());
        }
        stmt.bindLong(4, value.getOrderIndex());
        if (value.getAudioFilePath() == null) {
          stmt.bindNull(5);
        } else {
          stmt.bindString(5, value.getAudioFilePath());
        }
        stmt.bindLong(6, value.getDuration());
        stmt.bindLong(7, value.getCreatedAt());
      }
    };
    this.__deletionAdapterOfSentence = new EntityDeletionOrUpdateAdapter<Sentence>(__db) {
      @Override
      public String createQuery() {
        return "DELETE FROM `sentences` WHERE `id` = ?";
      }

      @Override
      public void bind(SupportSQLiteStatement stmt, Sentence value) {
        stmt.bindLong(1, value.getId());
      }
    };
    this.__updateAdapterOfSentence = new EntityDeletionOrUpdateAdapter<Sentence>(__db) {
      @Override
      public String createQuery() {
        return "UPDATE OR ABORT `sentences` SET `id` = ?,`textEntryId` = ?,`content` = ?,`orderIndex` = ?,`audioFilePath` = ?,`duration` = ?,`createdAt` = ? WHERE `id` = ?";
      }

      @Override
      public void bind(SupportSQLiteStatement stmt, Sentence value) {
        stmt.bindLong(1, value.getId());
        stmt.bindLong(2, value.getTextEntryId());
        if (value.getContent() == null) {
          stmt.bindNull(3);
        } else {
          stmt.bindString(3, value.getContent());
        }
        stmt.bindLong(4, value.getOrderIndex());
        if (value.getAudioFilePath() == null) {
          stmt.bindNull(5);
        } else {
          stmt.bindString(5, value.getAudioFilePath());
        }
        stmt.bindLong(6, value.getDuration());
        stmt.bindLong(7, value.getCreatedAt());
        stmt.bindLong(8, value.getId());
      }
    };
    this.__preparedStmtOfDeleteSentencesByTextEntryId = new SharedSQLiteStatement(__db) {
      @Override
      public String createQuery() {
        final String _query = "DELETE FROM sentences WHERE textEntryId = ?";
        return _query;
      }
    };
  }

  @Override
  public long insertSentence(final Sentence sentence) {
    __db.assertNotSuspendingTransaction();
    __db.beginTransaction();
    try {
      long _result = __insertionAdapterOfSentence.insertAndReturnId(sentence);
      __db.setTransactionSuccessful();
      return _result;
    } finally {
      __db.endTransaction();
    }
  }

  @Override
  public List<Long> insertSentences(final List<Sentence> sentences) {
    __db.assertNotSuspendingTransaction();
    __db.beginTransaction();
    try {
      List<Long> _result = __insertionAdapterOfSentence.insertAndReturnIdsList(sentences);
      __db.setTransactionSuccessful();
      return _result;
    } finally {
      __db.endTransaction();
    }
  }

  @Override
  public void deleteSentence(final Sentence sentence) {
    __db.assertNotSuspendingTransaction();
    __db.beginTransaction();
    try {
      __deletionAdapterOfSentence.handle(sentence);
      __db.setTransactionSuccessful();
    } finally {
      __db.endTransaction();
    }
  }

  @Override
  public void updateSentence(final Sentence sentence) {
    __db.assertNotSuspendingTransaction();
    __db.beginTransaction();
    try {
      __updateAdapterOfSentence.handle(sentence);
      __db.setTransactionSuccessful();
    } finally {
      __db.endTransaction();
    }
  }

  @Override
  public void deleteSentencesByTextEntryId(final long textEntryId) {
    __db.assertNotSuspendingTransaction();
    final SupportSQLiteStatement _stmt = __preparedStmtOfDeleteSentencesByTextEntryId.acquire();
    int _argIndex = 1;
    _stmt.bindLong(_argIndex, textEntryId);
    __db.beginTransaction();
    try {
      _stmt.executeUpdateDelete();
      __db.setTransactionSuccessful();
    } finally {
      __db.endTransaction();
      __preparedStmtOfDeleteSentencesByTextEntryId.release(_stmt);
    }
  }

  @Override
  public LiveData<List<Sentence>> getSentencesByTextEntryId(final long textEntryId) {
    final String _sql = "SELECT * FROM sentences WHERE textEntryId = ? ORDER BY orderIndex ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, textEntryId);
    return __db.getInvalidationTracker().createLiveData(new String[]{"sentences"}, false, new Callable<List<Sentence>>() {
      @Override
      public List<Sentence> call() throws Exception {
        final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
        try {
          final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
          final int _cursorIndexOfTextEntryId = CursorUtil.getColumnIndexOrThrow(_cursor, "textEntryId");
          final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
          final int _cursorIndexOfOrderIndex = CursorUtil.getColumnIndexOrThrow(_cursor, "orderIndex");
          final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
          final int _cursorIndexOfDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "duration");
          final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
          final List<Sentence> _result = new ArrayList<Sentence>(_cursor.getCount());
          while(_cursor.moveToNext()) {
            final Sentence _item;
            final long _tmpId;
            _tmpId = _cursor.getLong(_cursorIndexOfId);
            final long _tmpTextEntryId;
            _tmpTextEntryId = _cursor.getLong(_cursorIndexOfTextEntryId);
            final String _tmpContent;
            if (_cursor.isNull(_cursorIndexOfContent)) {
              _tmpContent = null;
            } else {
              _tmpContent = _cursor.getString(_cursorIndexOfContent);
            }
            final int _tmpOrderIndex;
            _tmpOrderIndex = _cursor.getInt(_cursorIndexOfOrderIndex);
            final String _tmpAudioFilePath;
            if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
              _tmpAudioFilePath = null;
            } else {
              _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
            }
            final long _tmpDuration;
            _tmpDuration = _cursor.getLong(_cursorIndexOfDuration);
            final long _tmpCreatedAt;
            _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
            _item = new Sentence(_tmpId,_tmpTextEntryId,_tmpContent,_tmpOrderIndex,_tmpAudioFilePath,_tmpDuration,_tmpCreatedAt);
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
  public List<Sentence> getSentencesByTextEntryIdSync(final long textEntryId) {
    final String _sql = "SELECT * FROM sentences WHERE textEntryId = ? ORDER BY orderIndex ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, textEntryId);
    __db.assertNotSuspendingTransaction();
    final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
    try {
      final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
      final int _cursorIndexOfTextEntryId = CursorUtil.getColumnIndexOrThrow(_cursor, "textEntryId");
      final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
      final int _cursorIndexOfOrderIndex = CursorUtil.getColumnIndexOrThrow(_cursor, "orderIndex");
      final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
      final int _cursorIndexOfDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "duration");
      final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
      final List<Sentence> _result = new ArrayList<Sentence>(_cursor.getCount());
      while(_cursor.moveToNext()) {
        final Sentence _item;
        final long _tmpId;
        _tmpId = _cursor.getLong(_cursorIndexOfId);
        final long _tmpTextEntryId;
        _tmpTextEntryId = _cursor.getLong(_cursorIndexOfTextEntryId);
        final String _tmpContent;
        if (_cursor.isNull(_cursorIndexOfContent)) {
          _tmpContent = null;
        } else {
          _tmpContent = _cursor.getString(_cursorIndexOfContent);
        }
        final int _tmpOrderIndex;
        _tmpOrderIndex = _cursor.getInt(_cursorIndexOfOrderIndex);
        final String _tmpAudioFilePath;
        if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
          _tmpAudioFilePath = null;
        } else {
          _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
        }
        final long _tmpDuration;
        _tmpDuration = _cursor.getLong(_cursorIndexOfDuration);
        final long _tmpCreatedAt;
        _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
        _item = new Sentence(_tmpId,_tmpTextEntryId,_tmpContent,_tmpOrderIndex,_tmpAudioFilePath,_tmpDuration,_tmpCreatedAt);
        _result.add(_item);
      }
      return _result;
    } finally {
      _cursor.close();
      _statement.release();
    }
  }

  @Override
  public Sentence getSentenceById(final long sentenceId) {
    final String _sql = "SELECT * FROM sentences WHERE id = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, sentenceId);
    __db.assertNotSuspendingTransaction();
    final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
    try {
      final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
      final int _cursorIndexOfTextEntryId = CursorUtil.getColumnIndexOrThrow(_cursor, "textEntryId");
      final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
      final int _cursorIndexOfOrderIndex = CursorUtil.getColumnIndexOrThrow(_cursor, "orderIndex");
      final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
      final int _cursorIndexOfDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "duration");
      final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
      final Sentence _result;
      if(_cursor.moveToFirst()) {
        final long _tmpId;
        _tmpId = _cursor.getLong(_cursorIndexOfId);
        final long _tmpTextEntryId;
        _tmpTextEntryId = _cursor.getLong(_cursorIndexOfTextEntryId);
        final String _tmpContent;
        if (_cursor.isNull(_cursorIndexOfContent)) {
          _tmpContent = null;
        } else {
          _tmpContent = _cursor.getString(_cursorIndexOfContent);
        }
        final int _tmpOrderIndex;
        _tmpOrderIndex = _cursor.getInt(_cursorIndexOfOrderIndex);
        final String _tmpAudioFilePath;
        if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
          _tmpAudioFilePath = null;
        } else {
          _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
        }
        final long _tmpDuration;
        _tmpDuration = _cursor.getLong(_cursorIndexOfDuration);
        final long _tmpCreatedAt;
        _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
        _result = new Sentence(_tmpId,_tmpTextEntryId,_tmpContent,_tmpOrderIndex,_tmpAudioFilePath,_tmpDuration,_tmpCreatedAt);
      } else {
        _result = null;
      }
      return _result;
    } finally {
      _cursor.close();
      _statement.release();
    }
  }

  @Override
  public int getSentenceCountForTextEntry(final long textEntryId) {
    final String _sql = "SELECT COUNT(*) FROM sentences WHERE textEntryId = ?";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, textEntryId);
    __db.assertNotSuspendingTransaction();
    final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
    try {
      final int _result;
      if(_cursor.moveToFirst()) {
        _result = _cursor.getInt(0);
      } else {
        _result = 0;
      }
      return _result;
    } finally {
      _cursor.close();
      _statement.release();
    }
  }

  @Override
  public List<Sentence> getSentencesWithoutAudio(final long textEntryId) {
    final String _sql = "SELECT * FROM sentences WHERE textEntryId = ? AND audioFilePath IS NULL ORDER BY orderIndex ASC";
    final RoomSQLiteQuery _statement = RoomSQLiteQuery.acquire(_sql, 1);
    int _argIndex = 1;
    _statement.bindLong(_argIndex, textEntryId);
    __db.assertNotSuspendingTransaction();
    final Cursor _cursor = DBUtil.query(__db, _statement, false, null);
    try {
      final int _cursorIndexOfId = CursorUtil.getColumnIndexOrThrow(_cursor, "id");
      final int _cursorIndexOfTextEntryId = CursorUtil.getColumnIndexOrThrow(_cursor, "textEntryId");
      final int _cursorIndexOfContent = CursorUtil.getColumnIndexOrThrow(_cursor, "content");
      final int _cursorIndexOfOrderIndex = CursorUtil.getColumnIndexOrThrow(_cursor, "orderIndex");
      final int _cursorIndexOfAudioFilePath = CursorUtil.getColumnIndexOrThrow(_cursor, "audioFilePath");
      final int _cursorIndexOfDuration = CursorUtil.getColumnIndexOrThrow(_cursor, "duration");
      final int _cursorIndexOfCreatedAt = CursorUtil.getColumnIndexOrThrow(_cursor, "createdAt");
      final List<Sentence> _result = new ArrayList<Sentence>(_cursor.getCount());
      while(_cursor.moveToNext()) {
        final Sentence _item;
        final long _tmpId;
        _tmpId = _cursor.getLong(_cursorIndexOfId);
        final long _tmpTextEntryId;
        _tmpTextEntryId = _cursor.getLong(_cursorIndexOfTextEntryId);
        final String _tmpContent;
        if (_cursor.isNull(_cursorIndexOfContent)) {
          _tmpContent = null;
        } else {
          _tmpContent = _cursor.getString(_cursorIndexOfContent);
        }
        final int _tmpOrderIndex;
        _tmpOrderIndex = _cursor.getInt(_cursorIndexOfOrderIndex);
        final String _tmpAudioFilePath;
        if (_cursor.isNull(_cursorIndexOfAudioFilePath)) {
          _tmpAudioFilePath = null;
        } else {
          _tmpAudioFilePath = _cursor.getString(_cursorIndexOfAudioFilePath);
        }
        final long _tmpDuration;
        _tmpDuration = _cursor.getLong(_cursorIndexOfDuration);
        final long _tmpCreatedAt;
        _tmpCreatedAt = _cursor.getLong(_cursorIndexOfCreatedAt);
        _item = new Sentence(_tmpId,_tmpTextEntryId,_tmpContent,_tmpOrderIndex,_tmpAudioFilePath,_tmpDuration,_tmpCreatedAt);
        _result.add(_item);
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
