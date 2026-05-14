package com.college.notice.notice.repository;

import com.college.notice.notice.entity.Notice;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NoticeRepository extends JpaRepository<Notice, Long> {

    @Query("""
            select distinct n
            from Notice n
            left join fetch n.targets t
            join fetch n.createdBy cb
            where (
                    t is null
                    or (t.department = :department and t.year = :year)
                  )
              and (n.expiryDate is null or n.expiryDate >= :visibilityCutoff)
            order by n.createdAt desc
            """)
    List<Notice> findActiveNoticesVisibleForUser(
            @Param("department") String department,
            @Param("year") Integer year,
            @Param("visibilityCutoff") LocalDateTime visibilityCutoff
    );

    @Query("""
            select n
            from Notice n
            left join fetch n.targets
            join fetch n.createdBy
            where n.id = :noticeId
            """)
    java.util.Optional<Notice> findByIdWithTargets(@Param("noticeId") Long noticeId);

    @Query("""
            select distinct n
            from Notice n
            left join fetch n.targets
            where n.expiryDate is not null
              and n.expiryDate > :fromTime
              and n.expiryDate <= :toTime
            """)
    List<Notice> findNoticesExpiringBetween(
            @Param("fromTime") LocalDateTime fromTime,
            @Param("toTime") LocalDateTime toTime
    );
}
