"""
ClipIt Computer Vision Pipeline & Effect Compositor.
Uses MediaPipe Face Landmarker & Image Segmenter with OpenCV.
"""
import os
import sys
import json
import math
import argparse
import numpy as np
import cv2

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

FACE_MODEL_PATH = os.path.join(PROJECT_ROOT, 'windows', 'face_landmarker.task')
SEGMENTER_MODEL_PATH = os.path.join(PROJECT_ROOT, 'windows', 'selfie_segmenter.tflite')
CROWN_ASSET_PATH = os.path.join(PROJECT_ROOT, 'assets', 'effects', 'crown.png')
HORNS_ASSET_PATH = os.path.join(PROJECT_ROOT, 'assets', 'effects', 'devil_horns.png')
HALO_ASSET_PATH = os.path.join(PROJECT_ROOT, 'assets', 'effects', 'angel_halo.png')

_face_detector = None
_image_segmenter = None


def get_face_detector():
    global _face_detector
    if _face_detector is None:
        if os.path.exists(FACE_MODEL_PATH):
            base_options = python.BaseOptions(model_asset_path=FACE_MODEL_PATH)
            options = vision.FaceLandmarkerOptions(
                base_options=base_options,
                num_faces=2,
            )
            _face_detector = vision.FaceLandmarker.create_from_options(options)
    return _face_detector


def get_image_segmenter():
    global _image_segmenter
    if _image_segmenter is None:
        if os.path.exists(SEGMENTER_MODEL_PATH):
            base_options = python.BaseOptions(model_asset_path=SEGMENTER_MODEL_PATH)
            options = vision.ImageSegmenterOptions(
                base_options=base_options,
                output_confidence_masks=True,
            )
            _image_segmenter = vision.ImageSegmenter.create_from_options(options)
    return _image_segmenter


def analyze_frame(image_bgr):
    """Detects facial landmarks, eyes, head angle, and person silhouette."""
    h, w = image_bgr.shape[:2]
    result = {
        'width': w,
        'height': h,
        'face_detected': False,
        'person_detected': False,
        'left_eye': None,
        'right_eye': None,
        'forehead_top': None,
        'chin': None,
        'head_angle_deg': 0.0,
        'face_width': 0.0,
        'face_height': 0.0,
    }

    # 1. Face Landmarks
    try:
        detector = get_face_detector()
        if detector:
            rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
            mp_img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            detection = detector.detect(mp_img)
            if detection and detection.face_landmarks:
                lm = detection.face_landmarks[0]
                result['face_detected'] = True

                # Iris / eye centers (468: left iris, 473: right iris)
                lx, ly = int(lm[468].x * w), int(lm[468].y * h)
                rx, ry = int(lm[473].x * w), int(lm[473].y * h)
                result['left_eye'] = {'x': lx, 'y': ly}
                result['right_eye'] = {'x': rx, 'y': ry}

                # Forehead top (10) and chin (152)
                top_x, top_y = int(lm[10].x * w), int(lm[10].y * h)
                chin_x, chin_y = int(lm[152].x * w), int(lm[152].y * h)
                result['forehead_top'] = {'x': top_x, 'y': top_y}
                result['chin'] = {'x': chin_x, 'y': chin_y}

                # Cheeks (234, 454) for face width
                c1_x = int(lm[234].x * w)
                c2_x = int(lm[454].x * w)
                result['face_width'] = abs(c2_x - c1_x)
                result['face_height'] = abs(chin_y - top_y)

                # Head tilt angle
                angle_rad = math.atan2(ry - ly, rx - lx)
                result['head_angle_deg'] = math.degrees(angle_rad)
    except Exception as e:
        sys.stderr.write(f"Face detection error: {e}\n")

    # 2. Person Silhouette Mask
    mask = None
    try:
        segmenter = get_image_segmenter()
        if segmenter:
            rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
            mp_img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            seg_result = segmenter.segment(mp_img)
            if seg_result and seg_result.confidence_masks:
                raw_mask = seg_result.confidence_masks[0].numpy_view()
                # Resize mask to original image dimensions if needed
                if raw_mask.shape[:2] != (h, w):
                    mask = cv2.resize(raw_mask, (w, h), interpolation=cv2.INTER_LINEAR)
                else:
                    mask = raw_mask.copy()
                result['person_detected'] = True
    except Exception as e:
        sys.stderr.write(f"Segmentation error: {e}\n")

    return result, mask


def apply_effects(image_bgr, effect_ids, analysis, person_mask):
    """Composites real effects onto the image based on detected face and body."""
    h, w = image_bgr.shape[:2]
    output = image_bgr.copy()

    has_crown = 'CLP_FX_CROWN' in effect_ids or 'CLP_FX_CROWN_026' in effect_ids
    has_rage = 'CLP_FX_RAGE_SCREEN' in effect_ids
    has_red_filter = 'CLP_FX_RED_FILTER' in effect_ids
    has_golden = 'CLP_FX_GOLDEN_OP' in effect_ids
    has_bw = 'CLP_FX_CINEMATIC_BW' in effect_ids or 'CLP_FX_SIGMA_001' in effect_ids
    has_fire = 'CLP_FX_FIRE_AURA' in effect_ids
    has_lightning = 'CLP_FX_LIGHTNING' in effect_ids
    has_glitch = 'CLP_FX_GLITCH' in effect_ids
    has_storm = 'CLP_FX_RED_PARTICLE_STORM' in effect_ids
    has_emoji = 'CLP_FX_EMOJI_BURST' in effect_ids

    # ── 1. CINEMATIC B&W COLOR GRADE ─────────────────────────────────────────
    if has_bw:
        gray = cv2.cvtColor(output, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        contrast_gray = clahe.apply(gray)
        output = cv2.cvtColor(contrast_gray, cv2.COLOR_GRAY2BGR)

    # ── 2. RED FILTER & RAGE SCREEN COLOR PROCESSING ─────────────────────────
    if has_rage or has_red_filter:
        b, g, r = cv2.split(output)
        gain = 1.55 if has_rage else 1.35
        offset = 30 if has_rage else 15
        r = cv2.addWeighted(r, gain, np.zeros_like(r), 0, offset)
        g = (g * 0.40).astype(np.uint8)
        b = (b * 0.40).astype(np.uint8)
        output = cv2.merge([b, g, r])

    # ── 3. GOLDEN / OP FILTER GRADE ──────────────────────────────────────────
    if has_golden:
        b, g, r = cv2.split(output)
        r = cv2.addWeighted(r, 1.25, np.zeros_like(r), 0, 20)
        g = cv2.addWeighted(g, 1.12, np.zeros_like(g), 0, 12)
        b = (b * 0.55).astype(np.uint8)
        output = cv2.merge([b, g, r])

    # ── 4. TRACKED CROWN MOMENT ──────────────────────────────────────────────
    if has_crown and analysis.get('face_detected') and os.path.exists(CROWN_ASSET_PATH):
        crown_rgba = cv2.imread(CROWN_ASSET_PATH, cv2.IMREAD_UNCHANGED)
        if crown_rgba is not None and crown_rgba.shape[2] == 4:
            f_top = analysis['forehead_top']
            face_w = analysis['face_width'] if analysis.get('face_width', 0) > 0 else 120
            crown_w = int(face_w * 1.35)
            aspect = crown_rgba.shape[0] / crown_rgba.shape[1]
            crown_h = int(crown_w * aspect)

            resized_crown = cv2.resize(crown_rgba, (crown_w, crown_h), interpolation=cv2.INTER_AREA)

            cx = f_top['x'] - crown_w // 2
            cy = f_top['y'] - int(crown_h * 0.75)

            angle = analysis.get('head_angle_deg', 0.0)
            if abs(angle) > 1.0:
                M = cv2.getRotationMatrix2D((crown_w // 2, crown_h // 2), -angle, 1.0)
                resized_crown = cv2.warpAffine(
                    resized_crown, M, (crown_w, crown_h),
                    flags=cv2.INTER_LINEAR,
                    borderMode=cv2.BORDER_CONSTANT,
                    borderValue=(0, 0, 0, 0),
                )

            output = overlay_rgba(output, resized_crown, cx, cy)

    # ── 5. GLITCH / CHROMATIC DISPLACEMENT ───────────────────────────────────
    if has_glitch:
        b, g, r = cv2.split(output)
        shift = max(4, int(w * 0.01))
        # Shift red right, blue left
        r = np.roll(r, shift, axis=1)
        b = np.roll(b, -shift, axis=1)
        output = cv2.merge([b, g, r])

    return output


def overlay_rgba(bg_bgr, fg_rgba, x, y):
    """Overlays an RGBA image onto a BGR image with alpha blending."""
    bh, bw = bg_bgr.shape[:2]
    fh, fw = fg_rgba.shape[:2]

    # Calculate overlapping bounds
    x1, y1 = max(0, x), max(0, y)
    x2, y2 = min(bw, x + fw), min(bh, y + fh)

    if x1 >= x2 or y1 >= y2:
        return bg_bgr

    fg_x1 = x1 - x
    fg_y1 = y1 - y
    fg_x2 = fg_x1 + (x2 - x1)
    fg_y2 = fg_y1 + (y2 - y1)

    fg_crop = fg_rgba[fg_y1:fg_y2, fg_x1:fg_x2]
    alpha = (fg_crop[:, :, 3].astype(np.float32) / 255.0)[:, :, np.newaxis]
    fg_bgr = fg_crop[:, :, :3].astype(np.float32)

    bg_crop = bg_bgr[y1:y2, x1:x2].astype(np.float32)
    blended = (fg_bgr * alpha + bg_crop * (1.0 - alpha)).astype(np.uint8)

    bg_bgr[y1:y2, x1:x2] = blended
    return bg_bgr


def main():
    parser = argparse.ArgumentParser(description="ClipIt Vision Pipeline")
    parser.add_argument('--input', required=True, help="Path to input image frame")
    parser.add_argument('--output', required=True, help="Path to output image frame")
    parser.add_argument('--effects', nargs='*', default=[], help="List of effect IDs to apply")
    parser.add_argument('--detect-only', action='store_true', help="Only output detection metadata JSON")
    parser.add_argument('--metadata-out', default=None, help="Optional path to write metadata JSON")

    args = parser.parse_args()

    if not os.path.exists(args.input):
        sys.stderr.write(f"Error: input file {args.input} does not exist\n")
        sys.exit(1)

    image = cv2.imread(args.input)
    if image is None:
        sys.stderr.write(f"Error: failed to decode image {args.input}\n")
        sys.exit(1)

    analysis, mask = analyze_frame(image)

    if args.metadata_out:
        with open(args.metadata_out, 'w') as f:
            json.dump(analysis, f, indent=2)

    if args.detect_only:
        print(json.dumps(analysis))
        sys.exit(0)

    # Composite effects
    processed = apply_effects(image, args.effects, analysis, mask)

    out_dir = os.path.dirname(args.output)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    cv2.imwrite(args.output, processed)
    print(json.dumps({
        'status': 'success',
        'output': args.output,
        'analysis': analysis,
    }))


if __name__ == '__main__':
    main()
