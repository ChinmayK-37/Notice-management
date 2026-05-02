package com.college.notice.notice.event;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class NoticeCreatedEvent {
    private Long noticeId;
}
