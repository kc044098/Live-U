package com.toivan.mtcamera.mt_plugin;


import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.util.Log;
import android.view.Surface;
import android.view.WindowManager;

import java.io.IOException;


/**
 * 对Camera的封装，便于调用
 */
public class MtCamera {

    private final String TAG = "MtCamera";

    private Camera camera;

    private Context context;

    public MtCamera(Context context) {
        this.context = context;
    }

    public void openCamera(int cameraId, int width, int height) {

        camera = Camera.open(cameraId);

        Camera.Parameters parameters = camera.getParameters();
        parameters.setPreviewFormat(ImageFormat.NV21);
        parameters.setPreviewSize(width, height);
        camera.setParameters(parameters);

        setCameraDisplayOrientation(context, cameraId, camera);

        Log.i(TAG, "MtCamera open camera: " + cameraId);
    }

    public void setPreviewSurface(SurfaceTexture previewSurface) {
        try {
            camera.setPreviewTexture(previewSurface);
        } catch (IOException e) {
            Log.e(TAG, e.getMessage());
        }
    }

    public void startPreview() {
        camera.startPreview();
        Log.i(TAG, "MtCamera startPreview");
    }

    public void stopPreview() {
        camera.stopPreview();
        Log.i(TAG, "MtCamera stopPreview");
    }

    public void releaseCamera() {
        if (camera != null) {
            camera.setPreviewCallback(null);
            camera.stopPreview();
            camera.release();
            camera = null;
        }

        Log.i(TAG, "MtCamera releaseCamera");
    }

    private void setCameraDisplayOrientation(Context context, int cameraId, Camera camera) {
        Camera.CameraInfo info = new Camera.CameraInfo();
        Camera.getCameraInfo(cameraId, info);
        WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        if (windowManager == null) {
            Log.e(TAG, "WindowManager is null");
            return;
        }
        int rotation = windowManager.getDefaultDisplay().getRotation();
        int degrees = 0;
        switch (rotation) {
            case Surface.ROTATION_0:
                degrees = 0;
                break;
            case Surface.ROTATION_90:
                degrees = 90;
                break;
            case Surface.ROTATION_180:
                degrees = 180;
                break;
            case Surface.ROTATION_270:
                degrees = 270;
                break;
        }

        int result;
        if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (info.orientation + degrees) % 360;
            result = (360 - result) % 360;  // compensate the mirror
        } else {  // back-facing
            result = (info.orientation - degrees + 360) % 360;
        }
        camera.setDisplayOrientation(result);
    }
}
