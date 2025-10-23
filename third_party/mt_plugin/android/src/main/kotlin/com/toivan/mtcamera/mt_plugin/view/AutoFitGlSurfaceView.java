package com.toivan.mtcamera.mt_plugin.view;

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;

/**
 * A {@link GLSurfaceView} that can be adjusted to a specified aspect ratio.
 */
public class AutoFitGlSurfaceView extends GLSurfaceView {

    private int mRatioWidth = 0;
    private int mRatioHeight = 0;

    public AutoFitGlSurfaceView(Context context) {
        this(context, null);
    }

    public AutoFitGlSurfaceView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    /**
     * Sets the aspect ratio for this view. The size of the view will be measured based on the ratio
     * calculated from the parameters. Note that the actual sizes of parameters don't matter, that
     * is, calling setAspectRatio(2, 3) and setAspectRatio(4, 6) make the same result.
     *
     * @param width Relative horizontal size
     * @param height Relative vertical size
     */
    public void setAspectRatio(int width, int height) {
        if (width < 0 || height < 0) {
            throw new IllegalArgumentException("Size cannot be negative.");
        }
        mRatioWidth = width;
        mRatioHeight = height;
        requestLayout();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        int width = MeasureSpec.getSize(widthMeasureSpec);
        int height = MeasureSpec.getSize(heightMeasureSpec);
        if (0 == mRatioWidth || 0 == mRatioHeight) {
            setMeasuredDimension(width, height);
        } else {
            if (width < height * mRatioWidth / mRatioHeight) {
                int calcHeight = width * mRatioHeight / mRatioWidth;
                if (calcHeight >= height) {
                    setMeasuredDimension(width, calcHeight);
                } else {
                    setMeasuredDimension(height * mRatioWidth / mRatioHeight, height);
                }
            } else {
                int calcWidth = height * mRatioWidth / mRatioHeight;
                if (calcWidth >= width) {
                    setMeasuredDimension(calcWidth, height);
                } else {
                    setMeasuredDimension(width, width * mRatioHeight / mRatioWidth);
                }
            }
        }
    }

}
