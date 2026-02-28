package ex.ss.lib.tools.common;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.TextPaint;
import android.text.TextUtils;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.BackgroundColorSpan;
import android.text.style.ClickableSpan;
import android.text.style.ForegroundColorSpan;
import android.text.style.StrikethroughSpan;
import android.text.style.StyleSpan;
import android.text.style.UnderlineSpan;
import android.view.View;

import androidx.annotation.DimenRes;
import androidx.annotation.NonNull;

public class SpannableTools {

    private SpannableStringBuilder mSpannableStringBuilder;

    private SpannableTools(Builder builder) {
        mSpannableStringBuilder = builder.mSpannableStringBuilder;
    }

    private SpannableStringBuilder getSpannableStringBuilder() {
        return mSpannableStringBuilder;
    }

    public static final class Builder {
        private int index;
        private int textLength;
        private SpannableStringBuilder mSpannableStringBuilder;

        public Builder() {
            mSpannableStringBuilder = new SpannableStringBuilder();
        }

        public Builder text(CharSequence text) {
            if (TextUtils.isEmpty(text)) {
                throw new NullPointerException("SpannableHelper.Builder#text(CharSequence text) params can not be empty!");
            }
            index = mSpannableStringBuilder.length();
            textLength = text.length();
            mSpannableStringBuilder.append(text);
            return this;
        }

        public Builder color(int color) {
            ForegroundColorSpan colorSpan = new ForegroundColorSpan(color);
            mSpannableStringBuilder.setSpan(colorSpan, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        public Builder bgColor(int color) {
            BackgroundColorSpan colorSpan = new BackgroundColorSpan(color);
            mSpannableStringBuilder.setSpan(colorSpan, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        public Builder color(String color) {
            return color(Color.parseColor(color));
        }

        public Builder size(int size) {
            AbsoluteSizeSpan absoluteSizeSpan = new AbsoluteSizeSpan(size);
            mSpannableStringBuilder.setSpan(absoluteSizeSpan, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        public Builder size(int size, boolean isDp) {
            AbsoluteSizeSpan absoluteSizeSpan = new AbsoluteSizeSpan(size, isDp);
            mSpannableStringBuilder.setSpan(absoluteSizeSpan, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        public Builder size(Context context, @DimenRes int dimenRes) {
            return size((int) context.getResources().getDimension(dimenRes));
        }

        public Builder bold(boolean bold) {
            if (bold) {
                StyleSpan styleSpan = new StyleSpan(Typeface.BOLD);//粗体
                mSpannableStringBuilder.setSpan(styleSpan, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
            return this;
        }

        /**
         * 下划线
         */
        public Builder underline() {
            UnderlineSpan span = new UnderlineSpan();
            mSpannableStringBuilder.setSpan(span, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        /**
         * 删除线
         */
        public Builder strikethrough() {
            StrikethroughSpan span = new StrikethroughSpan();
            mSpannableStringBuilder.setSpan(span, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }


        /**
         * 点击
         *
         * @apiNote 使用这个属性需要设置 {@link android.widget.TextView#(android.text.method.LinkMovementMethod)}
         * @apiNote 同时设置颜色 {@link #color(int)} 需要放在此方法之后执行
         */
        public Builder click(final View.OnClickListener onClickListener) {
            ClickableSpan span = new ToolsClickableSpan(onClickListener);
            mSpannableStringBuilder.setSpan(span, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        public Builder click(int color, boolean underlineText, View.OnClickListener onClickListener) {
            ClickableSpan span = new ToolsClickableSpan(color, underlineText, onClickListener);
            mSpannableStringBuilder.setSpan(span, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        /**
         * 点击（直接设置ClickableSpan）
         *
         * @apiNote 使用这个属性需要设置 {@link android.widget.TextView#(android.text.method.LinkMovementMethod)}
         * @apiNote 同时设置颜色 {@link #color(int)} 需要放在此方法之后执行
         */
        public Builder click(ClickableSpan span) {
            mSpannableStringBuilder.setSpan(span, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        public Builder span(Object span) {
            mSpannableStringBuilder.setSpan(span, index, index + textLength, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return this;
        }

        public Spannable build() {
            return new SpannableTools(this).getSpannableStringBuilder();
        }
    }

    private static class ToolsClickableSpan extends ClickableSpan {

        private int color = 0;
        private boolean underlineText = true;
        private final View.OnClickListener onClickListener;

        public ToolsClickableSpan(View.OnClickListener onClickListener) {
            this.onClickListener = onClickListener;
        }

        public ToolsClickableSpan(int color, boolean underlineText, View.OnClickListener onClickListener) {
            this.color = color;
            this.underlineText = underlineText;
            this.onClickListener = onClickListener;
        }

        @Override
        public void onClick(@NonNull View widget) {
            if (onClickListener != null) {
                onClickListener.onClick(widget);
            }
        }

        @Override
        public void updateDrawState(@NonNull TextPaint ds) {
            super.updateDrawState(ds);
            if (color != 0) {
                ds.setColor(color);
            }
            ds.setUnderlineText(underlineText);
        }
    }

}
