package com.college.notice.notice.repository;

import com.college.notice.notice.entity.NoticeReply;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoticeReplyRepository extends JpaRepository<NoticeReply, Long> {

    List<NoticeReply> findByNoticeIdOrderByCreatedAtDesc(Long noticeId);

    List<NoticeReply> findByNoticeIdAndUserIdOrderByCreatedAtDesc(Long noticeId, Long userId);

    long countByNoticeId(Long noticeId);

    List<NoticeReply> findTop5ByOrderByCreatedAtDesc();
}

