package com.college.notice.notice.config;

import java.time.LocalDateTime;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Controls how far back expired notices remain visible in feeds.
 * Set {@code app.notice.expiry-grace-days} to a small positive value for demos.
 */
@Component
public class NoticeExpiryPolicy {

    @Value("${app.notice.expiry-grace-days:0}")
    private int graceDays;

    public LocalDateTime visibilityCutoff() {
        int days = Math.max(0, graceDays);
        return LocalDateTime.now().minusDays(days);
    }
}
