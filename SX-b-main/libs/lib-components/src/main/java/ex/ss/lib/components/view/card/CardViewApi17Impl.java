package ex.ss.lib.components.view.card;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;

public class CardViewApi17Impl extends CardViewBaseImpl {

    @Override
    public void initStatic() {
        RoundRectDrawableWithShadow.sRoundRectHelper =
                new RoundRectDrawableWithShadow.RoundRectHelper() {
                    @Override
                    public void drawRoundRect(Canvas canvas, RectF bounds, float cornerRadius,
                                              Paint paint) {
                        canvas.drawRoundRect(bounds, cornerRadius, cornerRadius, paint);
                    }
                };
    }
}
