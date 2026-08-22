import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_template/src/features/notes/note.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  final at = DateTime.utc(2026, 3, 4, 5, 6, 7);

  group('fromFirestore', () {
    test('reads a well-formed document', () {
      final note = Note.fromFirestore('id1', {
        'title': 'Hello',
        'body': 'World',
        'updatedAt': Timestamp.fromDate(at),
      });

      expect(note.id, 'id1');
      expect(note.title, 'Hello');
      expect(note.body, 'World');
      expect(note.updatedAt, at);
      expect(note.pendingSync, isFalse);
    });

    test('defaults missing text fields to empty strings', () {
      final note = Note.fromFirestore('id1', const {});
      expect(note.title, '');
      expect(note.body, '');
    });

    test('tolerates a wrongly-typed title rather than throwing', () {
      final note = Note.fromFirestore('id1', const {'title': 42});
      expect(note.title, '');
    });

    test('accepts a raw DateTime for updatedAt', () {
      expect(Note.fromFirestore('i', {'updatedAt': at}).updatedAt, at);
    });

    test('accepts epoch milliseconds for updatedAt', () {
      final note = Note.fromFirestore('i', {
        'updatedAt': at.millisecondsSinceEpoch,
      });
      expect(note.updatedAt, at);
    });

    test('falls back to the UTC epoch for an unusable updatedAt', () {
      final note = Note.fromFirestore('i', const {'updatedAt': 'nonsense'});
      expect(
        note.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });

    test('falls back to the UTC epoch when updatedAt is absent', () {
      expect(
        Note.fromFirestore('i', const {}).updatedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });

    test('normalises a local Timestamp to UTC', () {
      final local = DateTime(2026, 5, 6, 7, 8, 9);
      final note = Note.fromFirestore('i', {
        'updatedAt': Timestamp.fromDate(local),
      });

      expect(note.updatedAt.isUtc, isTrue);
      expect(note.updatedAt, local.toUtc());
    });

    test('tolerates a wrongly-typed body', () {
      expect(
        Note.fromFirestore('i', const {
          'body': ['a'],
        }).body,
        '',
      );
    });
  });

  group('toFirestore', () {
    test('writes title, body, and a Timestamp', () {
      final map = testNote(updatedAt: at).toFirestore();

      expect(map['title'], 'First note');
      expect(map['body'], 'Body text');
      expect(map['updatedAt'], timestampOf(at));
    });

    test('does not persist pendingSync — it is a local-only concern', () {
      expect(
        testNote(pendingSync: true).toFirestore(),
        isNot(contains('pendingSync')),
      );
    });

    test('round-trips through Firestore form', () {
      final original = testNote(updatedAt: at);
      final restored = Note.fromFirestore(original.id, original.toFirestore());
      expect(restored, original);
    });
  });

  group('row conversion', () {
    test('round-trips through the Drift row form', () {
      final original = testNote(pendingSync: true, updatedAt: at);
      expect(Note.fromRow(original.toRow()), original);
    });
  });

  group('preview', () {
    test('is the first non-blank line', () {
      expect(testNote(body: 'first\nsecond').preview, 'first');
    });

    test('skips leading blank lines', () {
      expect(testNote(body: '\n\n  \nreal content').preview, 'real content');
    });

    test('is empty for an empty body', () {
      expect(testNote(body: '').preview, '');
    });

    test('is empty for a whitespace-only body', () {
      expect(testNote(body: '   \n  ').preview, '');
    });

    test('passes through a line of exactly 80 characters', () {
      final line = 'x' * 80;
      expect(testNote(body: line).preview, line);
    });

    test('truncates a longer line with an ellipsis', () {
      final preview = testNote(body: 'y' * 200).preview;
      expect(preview, hasLength(80));
      expect(preview, endsWith('…'));
    });
  });

  group('displayTitle', () {
    test('uses the trimmed title', () {
      expect(testNote(title: '  Real  ').displayTitle, 'Real');
    });

    test('falls back for a blank title', () {
      expect(testNote(title: '   ').displayTitle, 'Untitled note');
    });

    test('falls back for an empty title', () {
      expect(testNote(title: '').displayTitle, 'Untitled note');
    });
  });

  group('isEmpty', () {
    test('is true when title and body are both blank', () {
      expect(testNote(title: ' ', body: '\n').isEmpty, isTrue);
    });

    test('is false when there is a title', () {
      expect(testNote(title: 'T', body: '').isEmpty, isFalse);
    });

    test('is false when there is a body', () {
      expect(testNote(title: '', body: 'B').isEmpty, isFalse);
    });
  });

  group('copyWith', () {
    test('changes only the named fields', () {
      final updated = testNote().copyWith(title: 'New');
      expect(updated.title, 'New');
      expect(updated.body, 'Body text');
      expect(updated.id, 'note-1');
    });

    test('is identity when given nothing', () {
      expect(testNote().copyWith(), testNote());
    });

    test('can flip pendingSync', () {
      expect(testNote().copyWith(pendingSync: true).pendingSync, isTrue);
    });
  });

  group('value equality', () {
    test('same fields are equal and hash alike', () {
      expect(testNote(), testNote());
      expect(testNote().hashCode, testNote().hashCode);
    });

    test('a different id is unequal', () {
      expect(testNote(id: 'a'), isNot(testNote(id: 'b')));
    });

    test('a different pendingSync is unequal', () {
      expect(testNote(), isNot(testNote(pendingSync: true)));
    });

    test('is not equal to an unrelated type', () {
      expect(testNote(), isNot(equals(7)));
    });

    test('toString includes the id, title, and pending flag', () {
      final text = testNote(pendingSync: true).toString();
      expect(text, contains('note-1'));
      expect(text, contains('First note'));
      expect(text, contains('true'));
    });
  });
}
