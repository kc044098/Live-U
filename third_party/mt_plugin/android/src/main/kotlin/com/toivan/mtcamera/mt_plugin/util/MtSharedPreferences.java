package com.toivan.mtcamera.mt_plugin.util;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;


import com.toivan.mtcamera.mt_plugin.model.MtSharedPrefKey;
import com.nimo.facebeauty.FBEffect;

public class MtSharedPreferences {
    //美颜
    public static final int WHITENESS_DEFAULT = 70;
    public static final int BLURRINESS_DEFAULT = 80;
    public static final int ROSINESS_DEFAULT = 10;
    public static final int CLEARNESS_DEFAULT = 5;
    public static final int BRIGHTNESS_DEFAULT = 0;
    public static final int UNDEREYE_CIRCLES_DEFAULT = 0;
    public static final int NASOLABIAL_FOLD_DEFAULT = 0;

    //美型
    public static final int EYE_ENLARGE_DEFAULT = 60;
    public static final int CHEEK_THIN_DEFAULT = 30;
    public static final int CHEEK_NARROW_DEFAULT = 0;
    public static final int CHEEK_BONE_THIN_DEFAULT = 0;
    public static final int JAW_BONE_THIN_DEFAULT = 0;
    public static final int TEMPLE_ENLARGE_DEFAULT = 0;
    public static final int HEAD_LESSEN_DEFAULT = 0;
    public static final int FACE_LESSEN_DEFAULT = 0;
    public static final int CHIN_TRIM_DEFAULT = 0;
    public static final int PHILTRUM_TRIM_DEFAULT = 0;
    public static final int FOREHEAD_TRIM_DEFAULT = 0;
    public static final int EYE_SPACE_DEFAULT = 0;
    public static final int EYE_CORNER_TRIM_DEFAULT = 0;
    public static final int EYE_CORNER_ENLARGE_DEFAULT = 0;
    public static final int NOSE_ENLARGE_DEFAULT = 0;
    public static final int NOSE_THIN_DEFAULT = 0;
    public static final int NOSE_APEX_DEFAULT = 0;
    public static final int NOSE_ROOT_DEFAULT = 0;
    public static final int MOUTH_TRIM_DEFAULT = 0;
    public static final int MOUTH_SMILE_DEFAULT = 0;

    private static MtSharedPreferences instance;
    private SharedPreferences mSharedPreferences;
    private FBEffect fbEffect;

    private MtSharedPreferences() {
    }

    public static MtSharedPreferences getInstance() {
        if (instance == null) {
            synchronized (MtSharedPreferences.class) {
                if (instance == null) {
                    instance = new MtSharedPreferences();
                }
            }
        }
        return instance;
    }

    public void init(Context context, FBEffect fbEffect) {
        this.fbEffect = fbEffect;
        mSharedPreferences = context.getSharedPreferences("MtSharedPreferences", Context.MODE_PRIVATE);
    }

    private void setBooleanValue(String key, boolean value) {
        SharedPreferences.Editor editor = mSharedPreferences.edit();
        editor.putBoolean(key, value);
        editor.apply();
    }

    private void setIntValue(String key, int value) {
        SharedPreferences.Editor editor = mSharedPreferences.edit();
        editor.putInt(key, value);
        editor.apply();
    }

    private void setStringValue(String key, String value) {
        SharedPreferences.Editor editor = mSharedPreferences.edit();
        editor.putString(key, value);
        editor.apply();
    }

    /**
     * UI版本
     */
    public void setUiVersion(String value) {
        setStringValue(MtSharedPrefKey.MT_UI_VERSION, value);
    }

    public String getUiVersion() {
        return mSharedPreferences.getString(MtSharedPrefKey.MT_UI_VERSION, "");
    }

    /**
     * 重置按钮
     */
    public void setBtnResetEnable(boolean value) {
        setBooleanValue(MtSharedPrefKey.BTN_RESET_ENABLE, value);
    }

    public boolean isBtnResetEnable() {
        return mSharedPreferences.getBoolean(MtSharedPrefKey.BTN_RESET_ENABLE, false);
    }

    /**
     * 美颜
     */
    public void setFaceBeautyEnable(boolean value) {
        setBooleanValue(MtSharedPrefKey.BEAUTY_ENABLE, value);
    }

    public boolean isFaceBeautyEnable() {
        return mSharedPreferences.getBoolean(MtSharedPrefKey.BEAUTY_ENABLE, true);
    }

    public void setWhitenessValue(int value) {
        setIntValue(MtSharedPrefKey.BEAUTY_WHITENESS, value);
    }

    public int getWhitenessValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.BEAUTY_WHITENESS, WHITENESS_DEFAULT);
    }

    public void setBlurrinessValue(int value) {
        setIntValue(MtSharedPrefKey.BEAUTY_BLURRINESS, value);
    }

    public int getBlurrinessValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.BEAUTY_BLURRINESS, BLURRINESS_DEFAULT);
    }

    public void setRosinessValue(int value) {
        setIntValue(MtSharedPrefKey.BEAUTY_ROSINESS, value);
    }

    public int getRosinessValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.BEAUTY_ROSINESS, ROSINESS_DEFAULT);
    }

    public void setClearnessValue(int value) {
        setIntValue(MtSharedPrefKey.BEAUTY_CLEARNESS, value);
    }

    public int getClearnessValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.BEAUTY_CLEARNESS, CLEARNESS_DEFAULT);
    }

    public void setBrightnessValue(int value) {
        setIntValue(MtSharedPrefKey.BEAUTY_BRIGHTNESS, value);
    }

    public int getBrightnessValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.BEAUTY_BRIGHTNESS, BRIGHTNESS_DEFAULT);
    }

    public void setUndereyeCirclesValue(int value) {
        setIntValue(MtSharedPrefKey.BEAUTY_UNDEREYE_CIRCLES, value);
    }


    public int getUndereyeCirclesValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.BEAUTY_UNDEREYE_CIRCLES, UNDEREYE_CIRCLES_DEFAULT);
    }

    public void setNasolabialFoldValue(int value) {
        setIntValue(MtSharedPrefKey.BEAUTY_NASOLABIAL_FOLD, value);
    }


    public int getNasolabialFoldValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.BEAUTY_NASOLABIAL_FOLD, NASOLABIAL_FOLD_DEFAULT);
    }


    /**
     * 美型
     */
    public void setFaceShapeEnable(boolean value) {
        setBooleanValue(MtSharedPrefKey.SHAPE_ENABLE, value);
    }

    public boolean isFaceShapeEnable() {
        return mSharedPreferences.getBoolean(MtSharedPrefKey.SHAPE_ENABLE, true);
    }

    public void setEyeEnlargingValue(int value) {   //大眼
        setIntValue(MtSharedPrefKey.SHAPE_EYE_ENLARGING, value);
    }

    public int getEyeEnlargingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_EYE_ENLARGING, EYE_ENLARGE_DEFAULT);
    }

    public void setCheekThinningValue(int value) {  //瘦脸
        setIntValue(MtSharedPrefKey.SHAPE_CHEEK_THINNING, value);
    }

    public int getCheekThinningValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_CHEEK_THINNING, CHEEK_THIN_DEFAULT);
    }

    public void setCheekNarrowingValue(int value) { //窄脸
        setIntValue(MtSharedPrefKey.SHAPE_CHEEK_NARROWING, value);
    }

    public int getCheekNarrowingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_CHEEK_NARROWING, CHEEK_NARROW_DEFAULT);
    }

    public void setCheekboneThinningValue(int value) { //瘦颧骨
        setIntValue(MtSharedPrefKey.SHAPE_CHEEK_BONE_THINNING, value);
    }

    public int getCheekboneThinningValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_CHEEK_BONE_THINNING, CHEEK_BONE_THIN_DEFAULT);
    }

    public void setJawboneThinningValue(int value) { //瘦下颌骨
        setIntValue(MtSharedPrefKey.SHAPE_JAW_BONE_THINNING, value);
    }

    public int getJawboneThinningValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_JAW_BONE_THINNING, JAW_BONE_THIN_DEFAULT);
    }

    public void setTempleEnlargingValue(int value) { //丰太阳穴
        setIntValue(MtSharedPrefKey.SHAPE_TEMPLE_ENLARGING, value);
    }

    public int getTempleEnlargingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_TEMPLE_ENLARGING, TEMPLE_ENLARGE_DEFAULT);
    }

    public void setHeadLesseningValue(int value) { //小头
        setIntValue(MtSharedPrefKey.SHAPE_HEAD_LESSENING, value);
    }

    public int getHeadLesseningValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_HEAD_LESSENING, HEAD_LESSEN_DEFAULT);
    }

    public void setFaceLesseningValue(int value) { //小脸
        setIntValue(MtSharedPrefKey.SHAPE_FACE_LESSENING, value);
    }

    public int getFaceLesseningValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_FACE_LESSENING, FACE_LESSEN_DEFAULT);
    }

    public void setChinTrimmingValue(int value) {   //下巴
        setIntValue(MtSharedPrefKey.SHAPE_CHIN_TRIMMING, value);
    }

    public int getChinTrimmingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_CHIN_TRIMMING, CHIN_TRIM_DEFAULT);
    }

    public void setPhiltrumTrimmingValue(int value) {   //缩人中
        setIntValue(MtSharedPrefKey.SHAPE_PHILTRUM_TRIMMING, value);
    }

    public int getPhiltrumTrimmingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_PHILTRUM_TRIMMING, PHILTRUM_TRIM_DEFAULT);
    }

    public void setForeheadTrimmingValue(int value) {   //发际线
        setIntValue(MtSharedPrefKey.SHAPE_FOREHEAD_TRIMMING, value);
    }

    public int getForeheadTrimmingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_FOREHEAD_TRIMMING, FOREHEAD_TRIM_DEFAULT);
    }

    public void setEyeSpacingTrimmingValue(int value) { //眼间距
        setIntValue(MtSharedPrefKey.SHAPE_EYE_SPACING, value);
    }

    public int getEyeSpacingTrimmingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_EYE_SPACING, EYE_SPACE_DEFAULT);
    }

    public void setEyeCornerTrimmingValue(int value) {  //倾斜（眼角）
        setIntValue(MtSharedPrefKey.SHAPE_EYE_CORNER_TRIMMING, value);
    }

    public int getEyeCornerTrimmingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_EYE_CORNER_TRIMMING, EYE_CORNER_TRIM_DEFAULT);
    }

    public void setEyeCornerEnlargingValue(int value) {  //开眼角
        setIntValue(MtSharedPrefKey.SHAPE_EYE_CORNER_ENLARGING, value);
    }

    public int getEyeCornerEnlargingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_EYE_CORNER_ENLARGING, EYE_CORNER_ENLARGE_DEFAULT);
    }

    public void setNoseEnlargingValue(int value) {  //长鼻
        setIntValue(MtSharedPrefKey.SHAPE_NOSE_ENLARGING, value);
    }

    public int getNoseEnlargingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_NOSE_ENLARGING, NOSE_ENLARGE_DEFAULT);
    }

    public void setNoseThinningValue(int value) {   //瘦鼻
        setIntValue(MtSharedPrefKey.SHAPE_NOSE_THINNING, value);
    }

    public int getNoseThinningValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_NOSE_THINNING, NOSE_THIN_DEFAULT);
    }

    public void setNoseApexLesseningValue(int value) {   //鼻头
        setIntValue(MtSharedPrefKey.SHAPE_NOSE_APEX_LESSENING, value);
    }

    public int getNoseApexLesseningValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_NOSE_APEX_LESSENING, NOSE_APEX_DEFAULT);
    }

    public void setNoseRootEnlargingValue(int value) {   //山根
        setIntValue(MtSharedPrefKey.SHAPE_NOSE_ROOT_ENLARGING, value);
    }

    public int getNoseRootEnlargingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_NOSE_ROOT_ENLARGING, NOSE_ROOT_DEFAULT);
    }

    public void setMouthTrimmingValue(int value) {  //嘴型
        setIntValue(MtSharedPrefKey.SHAPE_MOUTH_TRIMMING, value);
    }

    public int getMouthTrimmingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_MOUTH_TRIMMING, MOUTH_TRIM_DEFAULT);
    }

    public void setMouthSmilingEnlargingValue(int value) {  //微笑嘴角
        setIntValue(MtSharedPrefKey.SHAPE_MOUTH_SMILING, value);
    }

    public int getMouthSmilingEnlargingValue() {
        return mSharedPreferences.getInt(MtSharedPrefKey.SHAPE_MOUTH_SMILING, MOUTH_SMILE_DEFAULT);
    }


    //滤镜
    public void setBeautyFilterValue(String key, int value) {
        setIntValue(key, value);
    }

    public int getBeautyFilterValue(String key) {
        return mSharedPreferences.getInt(key, 100);
    }

    public void setEffectFilterValue(String key, int value) {
        setIntValue(key, value);
    }

    public int getEffectFilterValue(String key) {
        return mSharedPreferences.getInt(key, 100);
    }

    public void setToneFilterValue(String key, int value) {
        setIntValue(key, value);
    }

    public int getToneFilterValue(String key) {
        return mSharedPreferences.getInt(key, 100);
    }

    //一键美颜
    public void setQuickBeautyValue(String key, int value) {
        setIntValue(key, value);
    }

    public int getQuickBeautyValue(String key) {
        return mSharedPreferences.getInt(key, 100);
    }

    public void setDynamicStickerName(String value) {
        setStringValue(MtSharedPrefKey.DYNAMIC_STICKER, value);
    }

    public String getDynamicStickerName() {
        return mSharedPreferences.getString(MtSharedPrefKey.DYNAMIC_STICKER, "");
    }

    public void setHotStickerPosition(int value) {
        setIntValue(MtSharedPrefKey.HOT_STICKER_POSITION, value);
    }

    public int getHotStickerPosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.HOT_STICKER_POSITION, -1);
    }

    public void setFestivalStickerPosition(int value) {
        setIntValue(MtSharedPrefKey.FESTIVAL_STICKER_POSITION, value);
    }

    public int getFestivalStickerPosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.FESTIVAL_STICKER_POSITION, -1);
    }

    public void setCuteStickerPosition(int value) {
        setIntValue(MtSharedPrefKey.CUTE_STICKER_POSITION, value);
    }

    public int getCuteStickerPosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.CUTE_STICKER_POSITION, -1);
    }

    public void setExpressionRecreationName(String value, int position) {
        setStringValue(MtSharedPrefKey.EXPRESSION, value);
        setExpressionPosition(position);
    }

    public String getExpressionRecreationName() {
        return mSharedPreferences.getString(MtSharedPrefKey.EXPRESSION, "");
    }

    public void setExpressionPosition(int value) {
        setIntValue(MtSharedPrefKey.EXPRESSION_POSITION, value);
    }

    public int getExpressionPosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.EXPRESSION_POSITION, -1);
    }

    public void setMaskName(String value, int position) {
        setStringValue(MtSharedPrefKey.MASK, value);
        setMaskPosition(position);
    }

    public String getMaskName() {
        return mSharedPreferences.getString(MtSharedPrefKey.MASK, "");
    }

    public void setMaskPosition(int value) {
        setIntValue(MtSharedPrefKey.MASK_POSITION, value);
    }

    public int getMaskPosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.MASK_POSITION, -1);
    }

    public void setGiftName(String value, int position) {
        setStringValue(MtSharedPrefKey.GIFT, value);
        setGiftPosition(position);
    }

    public String getGiftName() {
        return mSharedPreferences.getString(MtSharedPrefKey.GIFT, "");
    }

    public void setGiftPosition(int value) {
        setIntValue(MtSharedPrefKey.GIFT_POSITION, value);
    }

    public int getGiftPosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.GIFT_POSITION, -1);
    }

    public void setAtmosphereItemName(String value, int position) {
        setStringValue(MtSharedPrefKey.ATMOSPHERE, value);
        setAtmospherePosition(position);
    }

    public String getAtmosphereItemName() {
        return mSharedPreferences.getString(MtSharedPrefKey.ATMOSPHERE, "");
    }

    public void setAtmospherePosition(int value) {
        setIntValue(MtSharedPrefKey.ATMOSPHERE_POSITION, value);
    }

    public int getAtmospherePosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.ATMOSPHERE_POSITION, -1);
    }

    public void setWatermarkName(String value, int position) {
        setStringValue(MtSharedPrefKey.WATERMARK, value);
        setWatermarkPosition(position);
    }

    public String getWatermarkName() {
        return mSharedPreferences.getString(MtSharedPrefKey.WATERMARK, "");
    }

    public void setWatermarkPosition(int value) {
        setIntValue(MtSharedPrefKey.WATERMARK_POSITION, value);
    }

    public int getWatermarkPosition() {
        return mSharedPreferences.getInt(MtSharedPrefKey.WATERMARK_POSITION, -1);
    }

    //初始化
    public void initAllSPValues() {
        fbEffect.setRenderEnable(isFaceBeautyEnable());
        fbEffect.setBeauty(0, getWhitenessValue());
        fbEffect.setBeauty(1, getBlurrinessValue());
        fbEffect.setBeauty(2, getRosinessValue());
        fbEffect.setBeauty(3, getClearnessValue());

        fbEffect.setReshape(10, getEyeEnlargingValue());
        fbEffect.setReshape(20, getCheekThinningValue());

        fbEffect.setFilter(0, "ziran3");
    }

    //重置
    public void reset() {

        fbEffect.setRenderEnable(isFaceBeautyEnable());

        fbEffect.setBeauty(0, WHITENESS_DEFAULT);
        fbEffect.setBeauty(1, BLURRINESS_DEFAULT);
        fbEffect.setBeauty(2, ROSINESS_DEFAULT);
        fbEffect.setBeauty(3, CLEARNESS_DEFAULT);

        setWhitenessValue(WHITENESS_DEFAULT);
        setBlurrinessValue(BLURRINESS_DEFAULT);
        setRosinessValue(ROSINESS_DEFAULT);
        setClearnessValue(CLEARNESS_DEFAULT);

        fbEffect.setReshape(10, EYE_ENLARGE_DEFAULT);
        fbEffect.setReshape(20, CHEEK_THIN_DEFAULT);

        setEyeEnlargingValue(EYE_ENLARGE_DEFAULT);
        setCheekThinningValue(CHEEK_THIN_DEFAULT);

        fbEffect.setFilter(0, "ziran3");
    }







}


