package com.college.notice.notification.repository;

import com.college.notice.auth.entity.User;
import com.college.notice.notice.entity.Notice;
import com.college.notice.notification.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);

    Page<Notification> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    Optional<Notification> findByIdAndUserId(Long id, Long userId);

    Optional<Notification> findFirstByNoticeIdAndUserIdOrderByIdAsc(Long noticeId, Long userId);

    boolean existsByUserAndNoticeAndType(User user, Notice notice, String type);
}
