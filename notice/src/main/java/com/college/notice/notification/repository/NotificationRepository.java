package com.college.notice.notification.repository;

import com.college.notice.auth.entity.User;
import com.college.notice.notice.entity.Notice;
import com.college.notice.notification.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);

    Page<Notification> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    @Query("""
            select n
            from Notification n
            join fetch n.notice notice
            where n.user.id = :userId
              and notice.state = com.college.notice.notice.entity.NoticeState.ACTIVE
              and (notice.expiryDate is null or notice.expiryDate >= :now)
            order by n.createdAt desc
            """)
    Page<Notification> findVisibleByUserIdOrderByCreatedAtDesc(
            @Param("userId") Long userId,
            @Param("now") LocalDateTime now,
            Pageable pageable
    );

    Optional<Notification> findByIdAndUserId(Long id, Long userId);

    Optional<Notification> findFirstByNoticeIdAndUserIdOrderByIdAsc(Long noticeId, Long userId);

    boolean existsByUserAndNoticeAndType(User user, Notice notice, String type);

    List<Notification> findTop5ByIsAcknowledgedTrueOrderByCreatedAtDesc();
}
