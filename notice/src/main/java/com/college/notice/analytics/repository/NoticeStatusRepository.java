package com.college.notice.analytics.repository;

import com.college.notice.analytics.entity.NoticeStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NoticeStatusRepository extends JpaRepository<NoticeStatus, Long> {

    long countByNoticeId(Long noticeId);

    long countByNoticeIdAndIsReadTrue(Long noticeId);

    long countByNoticeIdAndIsAcknowledgedTrue(Long noticeId);

    long countByNoticeIdAndViewedTrue(Long noticeId);

    Optional<NoticeStatus> findByUserIdAndNoticeId(Long userId, Long noticeId);

    @Query("""
            select ns
            from NoticeStatus ns
            join fetch ns.user
            where ns.notice.id = :noticeId
              and ns.isRead = false
            """)
    List<NoticeStatus> findUnreadStatusesByNoticeId(@Param("noticeId") Long noticeId);
}
