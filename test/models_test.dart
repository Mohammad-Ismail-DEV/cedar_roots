import 'package:cedar_roots/models/app_notification.dart';
import 'package:cedar_roots/models/connection.dart';
import 'package:cedar_roots/models/message.dart';
import 'package:cedar_roots/models/organization.dart';
import 'package:cedar_roots/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message', () {
    test('parses the server shape and status strings', () {
      final message = Message.fromJson({
        'id': 7,
        'sender_id': 1,
        'receiver_id': 2,
        'content': 'hi',
        'type': 'text',
        'sent_at': '2026-03-03T10:00:00.000Z',
        'read_status': 'delivered',
      });

      expect(message.id, 7);
      expect(message.status, MessageStatus.delivered);
      expect(message.isMine(1), isTrue);
      expect(message.isMine(2), isFalse);
    });

    test('unknown or legacy statuses fall back to sent', () {
      for (final legacy in [null, 0, 1, false, 'whatever']) {
        expect(MessageStatus.parse(legacy), MessageStatus.sent);
      }
    });

    test('round-trips through toJson', () {
      final original = Message.fromJson({
        'id': 3,
        'sender_id': 1,
        'receiver_id': 2,
        'content': 'x',
        'sent_at': '2026-03-03T10:00:00.000Z',
        'read_status': 'seen',
      });
      final copy = Message.fromJson(original.toJson());

      expect(copy.id, original.id);
      expect(copy.status, MessageStatus.seen);
      expect(copy.sentAt.toUtc(), original.sentAt.toUtc());
    });
  });

  group('Conversation', () {
    test('reads the last message and unread count', () {
      final c = Conversation.fromJson({
        'user_id': 5,
        'name': 'Ada',
        'profile_pic': null,
        'unread_count': 3,
        'last_message': {
          'id': 1,
          'sender_id': 5,
          'receiver_id': 1,
          'content': 'yo',
          'sent_at': '2026-03-03T10:00:00.000Z',
          'read_status': 'sent',
        },
      });

      expect(c.userId, 5);
      expect(c.unreadCount, 3);
      expect(c.lastMessage?.content, 'yo');
    });
  });

  group('AppNotification', () {
    test('accepts data as a map or as a JSON string', () {
      Map<String, dynamic> row(Object? data) => {
        'id': 1,
        'type': 'like',
        'message': 'm',
        'is_read': 0,
        'data': data,
      };

      final fromMap = AppNotification.fromJson(
        row({'postId': 4, 'notificationType': 'comment'}),
      );
      final fromString = AppNotification.fromJson(
        row('{"postId":"4","notificationType":"comment"}'),
      );

      expect(fromMap.data['postId'], '4');
      expect(fromString.data['postId'], '4');
      expect(fromMap.routeType, 'comment');
      expect(fromString.routeType, 'comment');
      expect(fromMap.isRead, isFalse);
    });

    test('survives missing or broken data', () {
      expect(AppNotification.fromJson({'id': 1, 'data': null}).data, isEmpty);
      expect(
        AppNotification.fromJson({'id': 1, 'data': '{oops'}).data,
        isEmpty,
      );
      expect(
        AppNotification.fromJson({'id': 1, 'type': 'like'}).routeType,
        'like',
      );
    });
  });

  group('Connection', () {
    test('other() returns the user on the far side', () {
      final c = Connection.fromJson({
        'id': 1,
        'sender_id': 10,
        'receiver_id': 20,
        'status': 'accepted',
        'Sender': {'id': 10, 'name': 'Sender'},
        'Receiver': {'id': 20, 'name': 'Receiver'},
      });

      expect(c.other(10)?.name, 'Receiver');
      expect(c.other(20)?.name, 'Sender');
    });

    test('status strings from the server', () {
      expect(
        ConnectionStatus.parse('pending_sent'),
        ConnectionStatus.pendingSent,
      );
      expect(
        ConnectionStatus.parse('pending_received'),
        ConnectionStatus.pendingReceived,
      );
      expect(ConnectionStatus.parse('accepted'), ConnectionStatus.accepted);
      expect(ConnectionStatus.parse('none'), ConnectionStatus.none);
      expect(ConnectionStatus.parse(null), ConnectionStatus.none);
    });
  });

  group('Organization', () {
    final org = Organization.fromJson({
      'id': 1,
      'name': 'Cedars',
      'OrganizationMembers': [
        {
          'user_id': 1,
          'organization_id': 1,
          'role': 'owner',
          'User': {'id': 1, 'name': 'A'},
        },
        {
          'user_id': 2,
          'organization_id': 1,
          'role': 'member',
          'User': {'id': 2, 'name': 'B'},
        },
      ],
      'OrganizationFollowers': [
        {
          'user_id': 3,
          'User': {'id': 3, 'name': 'C'},
        },
      ],
      'Events': [
        {
          'id': 9,
          'title': 'Meetup',
          'organization_id': 1,
          'date_time': '2026-04-01T18:00:00.000Z',
        },
      ],
    });

    test('knows roles, followers and events', () {
      expect(org.roleOf(1), OrgRole.owner);
      expect(org.roleOf(2)?.canManage, isFalse);
      expect(org.roleOf(99), isNull);
      expect(org.isFollowedBy(3), isTrue);
      expect(org.isFollowedBy(2), isFalse);
      expect(org.events.single.title, 'Meetup');
    });
  });

  group('Post', () {
    test('tracks likes and comments', () {
      final post = Post.fromJson({
        'id': 1,
        'user_id': 2,
        'content': 'hello',
        'created_at': '2026-03-03T10:00:00.000Z',
        'User': {'id': 2, 'name': 'Author'},
        'Likes': [
          {'user_id': 5},
        ],
        'Comments': [
          {
            'id': 1,
            'user_id': 5,
            'post_id': 1,
            'content': 'nice',
            'Author': {'id': 5, 'name': 'Fan'},
          },
        ],
      });

      expect(post.isLikedBy(5), isTrue);
      expect(post.isLikedBy(2), isFalse);
      expect(post.comments.single.author?.name, 'Fan');
      expect(post.copyWith(likes: const []).likes, isEmpty);
    });
  });
}
