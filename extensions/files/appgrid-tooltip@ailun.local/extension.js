// App Grid Tooltip
// 应用网格里，鼠标悬停在图标上时，如果名称被省略号截断，就弹出提示框显示完整名称。

import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Pango from 'gi://Pango';
import St from 'gi://St';

import * as AppDisplay from 'resource:///org/gnome/shell/ui/appDisplay.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const HOVER_DELAY = 350;
const MAX_WIDTH = 420;

// 判断标签在当前状态下是否真的显示不全：
// 1) 仍处于 ellipsize 状态 -> 一行就被截断
// 2) 已经换行展开，但可用高度放不下全部文本 -> 被裁切
function isTruncated(label) {
    if (!label || !label.clutter_text)
        return false;

    try {
        const layout = label.clutter_text.get_layout();
        if (layout.is_ellipsized())
            return true;

        const [, naturalHeight] = layout.get_pixel_size();
        return naturalHeight > label.height + 1;
    } catch (e) {
        return false;
    }
}

export default class AppGridTooltipExtension extends Extension {
    enable() {
        this._tooltips = new Set();
        this._origInit = AppDisplay.AppIcon.prototype._init;

        const origInit = this._origInit;
        const self = this;

        AppDisplay.AppIcon.prototype._init = function (app, iconParams) {
            origInit.call(this, app, iconParams);
            try {
                self._attach(this);
            } catch (e) {
                console.error(`[appgrid-tooltip] attach failed: ${e}`);
            }
        };

        this._overviewHideId = Main.overview.connect('hiding', () => {
            for (const e of this._tooltips) {
                if (e.timeoutId > 0) {
                    GLib.source_remove(e.timeoutId);
                    e.timeoutId = 0;
                }
                e.tooltip.hide();
                e.tooltip.opacity = 0;
            }
        });
    }

    disable() {
        if (this._overviewHideId) {
            Main.overview.disconnect(this._overviewHideId);
            this._overviewHideId = 0;
        }

        if (this._origInit) {
            AppDisplay.AppIcon.prototype._init = this._origInit;
            this._origInit = null;
        }

        for (const t of this._tooltips) {
            if (t.tooltip)
                t.tooltip.destroy();
        }
        this._tooltips.clear();
        this._tooltips = null;
    }

    _attach(icon) {
        const label = icon.icon ? icon.icon.label : null;
        if (!label)
            return;

        const name = icon.app ? icon.app.get_name() : label.text;
        if (!name || name.length < 2)
            return;

        const tooltip = new St.Label({
            style_class: 'appgrid-tooltip',
            text: name,
            visible: false,
            reactive: false,
            opacity: 0,
        });
        tooltip.clutter_text.set({
            line_wrap: true,
            line_wrap_mode: Pango.WrapMode.WORD_CHAR,
            ellipsize: Pango.EllipsizeMode.NONE,
        });
        Main.uiGroup.add_child(tooltip);

        const entry = {icon, tooltip, timeoutId: 0};
        this._tooltips.add(entry);

        const hide = () => {
            if (entry.timeoutId > 0) {
                GLib.source_remove(entry.timeoutId);
                entry.timeoutId = 0;
            }
            tooltip.remove_all_transitions();
            tooltip.ease({
                opacity: 0,
                duration: 100,
                mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                onComplete: () => {
                    tooltip.hide();
                },
            });
        };

        icon.connect('notify::hover', () => {
            if (!icon.hover) {
                hide();
                return;
            }

            // 名称完整显示时不需要提示框
            if (!isTruncated(label)) {
                hide();
                return;
            }

            if (entry.timeoutId > 0)
                return;

            entry.timeoutId = GLib.timeout_add_once(
                GLib.PRIORITY_DEFAULT, HOVER_DELAY, () => {
                    entry.timeoutId = 0;
                    if (!icon.hover || !icon.mapped) {
                        hide();
                        return;
                    }
                    this._show(entry);
                });
            GLib.Source.set_name_by_id(entry.timeoutId,
                '[appgrid-tooltip] show');
        });

        icon.connect('destroy', () => {
            if (entry.timeoutId > 0) {
                GLib.source_remove(entry.timeoutId);
                entry.timeoutId = 0;
            }
            this._tooltips.delete(entry);
            tooltip.destroy();
        });

    }

    _show(entry) {
        const {icon, tooltip} = entry;

        const extents = icon.get_transformed_extents();
        if (extents.get_width() <= 0)
            return;

        const [, naturalWidth] = tooltip.get_preferred_width(-1);
        const tooltipWidth = Math.min(naturalWidth, MAX_WIDTH);
        tooltip.set_width(tooltipWidth);

        const [, tooltipHeight] = tooltip.get_preferred_height(tooltipWidth);

        const x = Math.clamp(
            Math.round(extents.get_x() + (extents.get_width() - tooltipWidth) / 2),
            8,
            Math.max(8, global.stage.width - tooltipWidth - 8));
        const y = Math.min(
            Math.round(extents.get_y2() + 6),
            global.stage.height - tooltipHeight - 8);

        tooltip.set_position(x, y);
        tooltip.opacity = 0;
        tooltip.show();
        tooltip.ease({
            opacity: 255,
            duration: 120,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
        });
    }
}
