//
//  Localized.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

// MARK: - 일반 다국어 텍스트
enum Localized: String {
    case `action.add`
    case `action.cancel`
    case `action.confirm`
    case `action.delete`
    case `action.done`
    case `action.edit`
    case `action.reset`
    case `action.save`
    case `action.share`
    case `action.name`
    case `action.view_all`
    case `book_detail.add_quote`
    case `book_detail.edit_book_info`
    case `book_detail.edit_reading_info`
    case `book_detail.no_quotes`
    case `book_detail.photos`
    case `book_detail.saved_quotes`
    case `book_detail.reset_and_delete`
    case `book_detail.settings`
    case `camera.capture_button`
    case `camera.permission.go_to_settings`
    case `camera.permission.message`
    case `camera.permission.title`
    case `photo.delete_confirmation.message`
    case `photo.delete_confirmation.title`
    case `photo.save_failure.message`
    case `photo.save_failure.title`
    case `photo.save_success.message`
    case `photo.save_success.title`
    case `photo.save_to_gallery`
    case `photo.view`
    case `photo_library.permission.go_to_settings`
    case `photo_library.permission.message`
    case `photo_library.permission.title`
    case `quote_save.continue_editing`
    case `quote_save.discard`
    case `quote_save.discard_message`
    case `quote_save.discard_title`
    case `quote_save.error_message`
    case `quote_save.error_title`
    case `quote_save.page_label`
    case `quote_save.page_placeholder`
    case `quote_save.placeholder`
    case `quote_save.title`
    case `quote_save.message`
    case `quote_save.placeholder_text`
    case `tab.library`
    case `tab.search`
    case `tab.settings`
    case `edit_book.title`
    case `edit_book.book_title`
    case `edit_book.author`
    case `edit_book.cover_image`
    case `edit_book.change_cover`
    case `edit_book.reset_custom_info`
    case `edit_book.reset`
    case `edit_book.reset_confirmation_title`
    case `edit_book.reset_confirmation_message`
    case `reset_delete.title`
    case `reset_delete.reset_book_info`
    case `reset_delete.reset_reading_records`
    case `reset_delete.delete_book`
    case `reset_delete.reset_book_info_confirm_title`
    case `reset_delete.reset_book_info_confirm_message`
    case `reset_delete.reset_records_confirm_title`
    case `reset_delete.reset_records_confirm_message`
    case `reset_delete.delete_book_confirm_title`
    case `reset_delete.delete_book_confirm_message`

    // MARK: - Circular Menu Items
    case `circular_menu.book_detail.reading_record`
    case `circular_menu.book_detail.save_quote`
    case `circular_menu.book_detail.take_photo`
    case `circular_menu.library.take_photo`
    case `circular_menu.common.view`
    case `circular_menu.common.save`
    case `circular_menu.common.delete`
    case `circular_menu.common.share`
    case `circular_menu.common.edit`
    case `circular_menu.book_detail.remove_favorite`
    case `circular_menu.book_detail.add_favorite`

    // MARK: - Alert Messages
    case `alert.delete_quote.title`
    case `alert.delete_quote.message`
    case `alert.delete_book.title`
    case `alert.delete_book.message_format`
    case `alert.navigate_to_book_detail.title`
    case `alert.navigate_to_book_detail.message`
    case `alert.search.enter_query`
    case `alert.search.no_results`
    case `alert.error.generic_message_format`
    case `alert.delete_reading_record.title`
    case `alert.delete_reading_record.message`
    case `alert.reading_timer.exit_without_saving.title`
    case `alert.reading_timer.exit_without_saving.message`
    case `alert.reading_timer.discard_session.title`
    case `alert.reading_timer.discard_session.message`
    case `alert.reading_timer.exit`
    case `alert.reading_timer.discard`
    case `alert.quote_share.save_failed.title`
    case `alert.quote_share.save_failed.message`
    case `alert.library.delete_book_single.message_format`
    case `alert.library.delete_books_multiple.message_format`
    case `alert.library.delete_failed.title`
    case `alert.library.delete_failed.message`

    // MARK: - Empty States
    case `empty_state.book_detail.no_reading_records`
    case `empty_state.book_detail.no_saved_quotes`
    case `empty_state.book_detail.no_photos`
    case `empty_state.library.no_books`

    // MARK: - Settings
    case `settings.section.general`
    case `settings.section.data`
    case `settings.section.contact`
    case `settings.section.info`
    case `settings.row.language`
    case `settings.row.reset_data`
    case `settings.row.contact`
    case `settings.row.app_version`
    case `settings.contact.instagram`
    case `settings.contact.email`
    case `settings.alert.reset_data.title`
    case `settings.alert.reset_data.message`
    case `settings.alert.language_selection.title`
    case `settings.alert.language_selection.message`
    case `settings.alert.language_changed.title`
    case `settings.alert.language_changed.message`

    // MARK: - Additional Book Detail
    case `book_detail.reading_records`

    // MARK: - Additional Actions
    case `action.select_all`
    case `action.deselect_all`

    // MARK: - Reading Timer
    case `reading_timer.title`
    case `reading_timer.remaining_time`
    case `reading_timer.start`
    case `reading_timer.pause`
    case `reading_timer.resume`
    case `reading_timer.take_photo`
    case `reading_timer.save_quote`
    case `reading_timer.exit_title`
    case `reading_timer.exit_message_short`
    case `reading_timer.save_title`
    case `reading_timer.save_and_exit`
    case `reading_timer.completion_title`
    case `reading_timer.notification_permission_title`
    case `reading_timer.notification_permission_message`
    case `reading_timer.start_without_notification`
    case `reading_timer.live_activity_disabled_title`
    case `reading_timer.live_activity_disabled_message`
    case `reading_timer.duplicate_session_title`
    case `reading_timer.continue_current`
    case `reading_timer.terminate_and_start`
    case `reading_timer.session_too_short_title`
    case `reading_timer.session_too_short_message`
    case `reading_timer.continue_reading`
    case `reading_timer.exit_without_saving`

    // MARK: - Search
    case `search.placeholder`
    case `search.book_saved.title`
    case `search.book_saved.message`
    case `search.navigate`
    case `alert.notification`
    case `search.empty_state.enter_query`
    case `search.empty_state.no_results`

    // MARK: - Reading Info Edit
    case `reading_info_edit.title`
    case `reading_info_edit.total_pages`
    case `reading_info_edit.pages_placeholder`
    case `reading_info_edit.start_date_label`
    case `reading_info_edit.clear_start_date`
    case `reading_info_edit.end_date_label`
    case `reading_info_edit.reading_status.reading`
    case `reading_info_edit.reading_status.completed`
    case `reading_info_edit.clear_end_date`
    case `reading_info_edit.date_error.title`
    case `reading_info_edit.date_error.message`
    case `reading_info_edit.start_date_cleared.title`
    case `reading_info_edit.start_date_cleared.message`
    case `reading_info_edit.end_date_cleared.title`
    case `reading_info_edit.end_date_cleared.message`

    // MARK: - Quote Share
    case `quote_share.title`
    case `quote_share.generating_image`
    case `quote_share.save_failed.title`
    case `quote_share.save_success.title`
    case `quote_share.save_success.message`
}
