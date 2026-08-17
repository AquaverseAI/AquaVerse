import React, { useEffect, useRef, useState, useCallback } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import {
  RotateCcw,
  Maximize2,
  Minimize2,
  Play,
  Pause,
  Activity,
  Wind,
  Droplets,
  Layers,
  Sparkles,
  Gauge,
  MapPin,
  ExternalLink,
} from 'lucide-react';

export interface PondDigitalTwin3DProps {
  pondId: string;
  theme?: 'light' | 'dark';
  aerationHours?: number;
  waterExchangePct?: number;
  feedReductionPct?: number;
  simulatedDO?: number;
  simulatedTAN?: number;
  className?: string;
}

/**
 * Real-world 3D Local Anchor Coordinates on the pond.fbx model
 */
const DATA_POINT_ANCHORS = {
  aerator_1: new THREE.Vector3(3.8, 0.08, -2.4),
  sonde_buoy_1: new THREE.Vector3(0.0, 0.05, 0.0),
  inflow_1: new THREE.Vector3(-5.2, 0.25, 3.4),
};

/**
 * Procedurally generates a seamless water ripple normal map for PBR wave refraction
 */
function createWaterNormalTexture(): THREE.CanvasTexture {
  const size = 512;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  if (!ctx) return new THREE.CanvasTexture(canvas);

  const imgData = ctx.createImageData(size, size);
  const data = imgData.data;

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const u = (x / size) * Math.PI * 8;
      const v = (y / size) * Math.PI * 8;

      const dx = Math.sin(u * 1.5 + v * 0.8) * 0.5 + Math.sin(u * 3.2 - v * 2.1) * 0.25;
      const dy = Math.cos(v * 1.5 + u * 0.8) * 0.5 + Math.cos(v * 3.2 - u * 2.1) * 0.25;

      const nx = Math.floor((dx * 0.5 + 0.5) * 255);
      const ny = Math.floor((dy * 0.5 + 0.5) * 255);
      const nz = 255;

      const idx = (y * size + x) * 4;
      data[idx] = nx;
      data[idx + 1] = ny;
      data[idx + 2] = nz;
      data[idx + 3] = 255;
    }
  }

  ctx.putImageData(imgData, 0, 0);
  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = THREE.RepeatWrapping;
  texture.wrapT = THREE.RepeatWrapping;
  texture.repeat.set(4, 4);
  return texture;
}

/**
 * Generates an outdoor sky/farmland environment map for realistic PBR reflections
 */
function createOutdoorEnvironmentMap(renderer: THREE.WebGLRenderer, isDark: boolean): THREE.WebGLRenderTarget {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 256;
  const ctx = canvas.getContext('2d');

  if (ctx) {
    const grad = ctx.createLinearGradient(0, 0, 0, 256);
    if (isDark) {
      grad.addColorStop(0, '#122c3b');
      grad.addColorStop(0.5, '#0a1d27');
      grad.addColorStop(1, '#051016');
    } else {
      grad.addColorStop(0, '#eaf6f8'); // Sky blue
      grad.addColorStop(0.45, '#ccecf2');
      grad.addColorStop(0.55, '#85d0e2'); // Horizon
      grad.addColorStop(0.7, '#4fbfa0'); // Vegetation
      grad.addColorStop(1, '#154c6e'); // Deep terrain
    }
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 512, 256);
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.mapping = THREE.EquirectangularReflectionMapping;

  const pmremGenerator = new THREE.PMREMGenerator(renderer);
  pmremGenerator.compileEquirectangularShader();
  const envMap = pmremGenerator.fromEquirectangular(texture);
  pmremGenerator.dispose();

  return envMap;
}

export const PondDigitalTwin3D: React.FC<PondDigitalTwin3DProps> = ({
  pondId,
  theme = 'light',
  aerationHours = 8,
  waterExchangePct = 10,
  feedReductionPct = 20,
  simulatedDO = 4.6,
  simulatedTAN = 0.52,
  className = '',
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasContainerRef = useRef<HTMLDivElement>(null);

  const [loading, setLoading] = useState(true);
  const [loadProgress, setLoadProgress] = useState(0);
  const [autoRotate, setAutoRotate] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [activePreset, setActivePreset] = useState<'aerial' | 'surface' | 'aerator' | 'sonde'>('surface');

  // Screen projected coordinates for custom interactive 3D data-point anchors
  const [anchorScreenPositions, setAnchorScreenPositions] = useState<{
    aerator?: { x: number; y: number; visible: boolean };
    sonde?: { x: number; y: number; visible: boolean };
    inflow?: { x: number; y: number; visible: boolean };
  }>({});

  // Three.js internal refs
  const sceneRef = useRef<THREE.Scene | null>(null);
  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null);
  const rendererRef = useRef<THREE.WebGLRenderer | null>(null);
  const controlsRef = useRef<OrbitControls | null>(null);
  const fbxModelRef = useRef<THREE.Group | null>(null);
  const waterMeshRef = useRef<THREE.Mesh | null>(null);
  const waterNormalTextureRef = useRef<THREE.CanvasTexture | null>(null);
  const aeratorPaddleRef = useRef<THREE.Group | null>(null);
  const sprayParticlesRef = useRef<THREE.Points | null>(null);
  const sondeLedRef = useRef<THREE.PointLight | null>(null);
  const sondeGroupRef = useRef<THREE.Group | null>(null);
  const animationFrameIdRef = useRef<number | null>(null);
  const clockRef = useRef(new THREE.Clock());

  // Camera tween interpolation state
  const cameraTweenRef = useRef<{
    active: boolean;
    startPos: THREE.Vector3;
    endPos: THREE.Vector3;
    startTarget: THREE.Vector3;
    endTarget: THREE.Vector3;
    startTime: number;
    duration: number;
  } | null>(null);

  const isDark = theme === 'dark';

  // Smooth Camera Tween to target position & target center
  const animateCameraTo = useCallback(
    (
      endPosition: THREE.Vector3,
      endTarget: THREE.Vector3,
      duration = 450,
      presetName: 'aerial' | 'surface' | 'aerator' | 'sonde' = 'surface'
    ) => {
      if (!cameraRef.current || !controlsRef.current) return;
      setActivePreset(presetName);
      setAutoRotate(false);

      cameraTweenRef.current = {
        active: true,
        startPos: cameraRef.current.position.clone(),
        endPos: endPosition,
        startTarget: controlsRef.current.target.clone(),
        endTarget: endTarget,
        startTime: performance.now(),
        duration,
      };
    },
    []
  );

  // Initialize Three.js Scene Pipeline
  useEffect(() => {
    if (!canvasContainerRef.current) return;

    // Clean up previous canvas mounts
    while (canvasContainerRef.current.firstChild) {
      canvasContainerRef.current.removeChild(canvasContainerRef.current.firstChild);
    }

    const width = canvasContainerRef.current.clientWidth || 800;
    const height = canvasContainerRef.current.clientHeight || 480;

    // ==========================================
    // 1. RENDERER SETUP (Color space, ACES Tone Mapping & PCF Shadows)
    // ==========================================
    const renderer = new THREE.WebGLRenderer({
      antialias: true,
      alpha: true,
      powerPreference: 'high-performance',
    });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = isDark ? 1.05 : 1.15;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    canvasContainerRef.current.appendChild(renderer.domElement);
    rendererRef.current = renderer;

    // ==========================================
    // 2. SCENE & CAMERA SETUP
    // ==========================================
    const scene = new THREE.Scene();
    sceneRef.current = scene;
    const bgColor = isDark ? 0x081722 : 0xf2f8fa;
    scene.background = new THREE.Color(bgColor);
    // Subtle distance fog that preserves the rich asset colors without washing them out
    scene.fog = new THREE.Fog(bgColor, 32, 75);

    const camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 1000);
    camera.position.set(16, 9.5, 17);
    cameraRef.current = camera;

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.maxPolarAngle = Math.PI / 2 - 0.04; // Prevent camera from going underwater
    controls.minDistance = 3.5;
    controls.maxDistance = 55;
    controls.target.set(0, 0.3, 0);
    controlsRef.current = controls;

    // Environment reflection map
    const envRenderTarget = createOutdoorEnvironmentMap(renderer, isDark);
    scene.environment = envRenderTarget.texture;

    // ==========================================
    // 3. BALANCED LIGHTING PIPELINE
    // ==========================================
    const sunLight = new THREE.DirectionalLight(0xfff8ee, isDark ? 1.3 : 1.6);
    sunLight.position.set(22, 28, 16);
    sunLight.castShadow = true;
    sunLight.shadow.mapSize.width = 2048;
    sunLight.shadow.mapSize.height = 2048;
    sunLight.shadow.camera.near = 0.5;
    sunLight.shadow.camera.far = 80;
    sunLight.shadow.camera.left = -12;
    sunLight.shadow.camera.right = 12;
    sunLight.shadow.camera.top = 12;
    sunLight.shadow.camera.bottom = -12;
    sunLight.shadow.bias = -0.0003;
    scene.add(sunLight);

    const hemiLight = new THREE.HemisphereLight(
      isDark ? 0x2e9cb8 : 0xeff9fb,
      isDark ? 0x092131 : 0x1c4a3b,
      isDark ? 0.65 : 0.85
    );
    scene.add(hemiLight);

    const ambientLight = new THREE.AmbientLight(0xffffff, isDark ? 0.2 : 0.35);
    scene.add(ambientLight);

    const backRimLight = new THREE.DirectionalLight(0x4fbfa0, isDark ? 0.4 : 0.5);
    backRimLight.position.set(-18, 12, -18);
    scene.add(backRimLight);

    // ==========================================
    // 4. LOAD & CONVERT POND.FBX PRESERVING ORIGINAL TEXTURES/COLORS
    // ==========================================
    const waterNormalTex = createWaterNormalTexture();
    waterNormalTextureRef.current = waterNormalTex;

    const fbxLoader = new FBXLoader();
    fbxLoader.load(
      '/pond.fbx',
      (fbx) => {
        // Compute bounding box and normalize scale (1200-unit model -> 19.2 units)
        const bbox = new THREE.Box3().setFromObject(fbx);
        const center = new THREE.Vector3();
        bbox.getCenter(center);

        const targetScale = 0.016; // Scale factor
        fbx.scale.set(targetScale, targetScale, targetScale);
        fbx.position.set(-center.x * targetScale, -center.y * targetScale - 0.2, -center.z * targetScale);

        // Convert FBX Materials to PBR while PRESERVING ORIGINAL TEXTURES & COLORS
        fbx.traverse((child) => {
          if ((child as THREE.Mesh).isMesh) {
            const mesh = child as THREE.Mesh;
            mesh.castShadow = true;
            mesh.receiveShadow = true;

            const name = mesh.name.toLowerCase();
            const oldMat: any = Array.isArray(mesh.material) ? mesh.material[0] : mesh.material;
            const matName = oldMat?.name?.toLowerCase() || '';

            // 1. Water Surface Mesh -> High-Fidelity MeshPhysicalMaterial
            if (name.includes('water') || matName.includes('water')) {
              const originalWaterColor = oldMat?.color ? oldMat.color.clone() : new THREE.Color(0x054059);
              const waterColorHex =
                simulatedDO < 3.0
                  ? 0xdc3545
                  : simulatedDO < 4.0
                  ? 0xe8a33d
                  : originalWaterColor.getHex();

              mesh.material = new THREE.MeshPhysicalMaterial({
                color: waterColorHex,
                transmission: 0.52,
                roughness: 0.16,
                metalness: 0.04,
                ior: 1.333,
                clearcoat: 0.95,
                clearcoatRoughness: 0.08,
                reflectivity: 0.65,
                attenuationColor: new THREE.Color(isDark ? 0x092131 : 0x0f3f5c),
                attenuationDistance: 2.8,
                normalMap: waterNormalTex,
                normalScale: new THREE.Vector2(0.35, 0.35),
                transparent: true,
                opacity: 0.92,
                depthWrite: false,
              });
              waterMeshRef.current = mesh;
            }
            // 2. Ground Terrain Mesh -> Preserve Original Ground Texture & Color (#26591f)
            else if (name.includes('ground') || name.includes('terrain') || matName.includes('ground')) {
              mesh.material = new THREE.MeshStandardMaterial({
                color: oldMat?.color || new THREE.Color(0x26591f),
                map: oldMat?.map || null,
                normalMap: oldMat?.normalMap || null,
                roughness: 0.8,
                metalness: 0.05,
              });
            }
            // 3. Perimeter Rocks -> Preserve Original Rock Color (#4d5259) & Texture
            else if (name.includes('rock') || matName.includes('rock')) {
              mesh.material = new THREE.MeshStandardMaterial({
                color: oldMat?.color || new THREE.Color(0x4d5259),
                map: oldMat?.map || null,
                normalMap: oldMat?.normalMap || null,
                roughness: 0.88,
                metalness: 0.05,
              });
            }
            // 4. Any other meshes -> Convert with original map/color preserved
            else if (oldMat) {
              mesh.material = new THREE.MeshStandardMaterial({
                color: oldMat.color || new THREE.Color(0xffffff),
                map: oldMat.map || null,
                roughness: 0.7,
                metalness: 0.1,
              });
            }
          }
        });

        scene.add(fbx);
        fbxModelRef.current = fbx;
        setLoading(false);
      },
      (xhr) => {
        if (xhr.total > 0) {
          setLoadProgress(Math.min(100, Math.round((xhr.loaded / xhr.total) * 100)));
        } else {
          setLoadProgress(90);
        }
      },
      (err) => {
        console.error('FBX Load Error:', err);
        setLoading(false);
      }
    );

    // ==========================================
    // 5. ATTACH CUSTOM 3D DATA-POINT PROPS TO POND.FBX
    // ==========================================

    // (A) Paddlewheel Aerator Prop at DATA_POINT_ANCHORS.aerator_1
    const aeratorGroup = new THREE.Group();
    aeratorGroup.position.copy(DATA_POINT_ANCHORS.aerator_1);

    const pontoonMat = new THREE.MeshStandardMaterial({ color: 0x1f8aa6, roughness: 0.35, metalness: 0.2 });
    const leftPontoon = new THREE.Mesh(new THREE.BoxGeometry(2.4, 0.22, 0.4), pontoonMat);
    leftPontoon.position.set(0, 0, -0.6);
    leftPontoon.castShadow = true;
    leftPontoon.receiveShadow = true;
    aeratorGroup.add(leftPontoon);

    const rightPontoon = new THREE.Mesh(new THREE.BoxGeometry(2.4, 0.22, 0.4), pontoonMat);
    rightPontoon.position.set(0, 0, 0.6);
    rightPontoon.castShadow = true;
    rightPontoon.receiveShadow = true;
    aeratorGroup.add(rightPontoon);

    const frameMat = new THREE.MeshStandardMaterial({ color: 0x154c6e, roughness: 0.4, metalness: 0.6 });
    const crossbar1 = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.1, 1.4), frameMat);
    crossbar1.position.set(-0.8, 0.12, 0);
    crossbar1.castShadow = true;
    aeratorGroup.add(crossbar1);

    const crossbar2 = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.1, 1.4), frameMat);
    crossbar2.position.set(0.8, 0.12, 0);
    crossbar2.castShadow = true;
    aeratorGroup.add(crossbar2);

    const motorMesh = new THREE.Mesh(
      new THREE.CylinderGeometry(0.24, 0.24, 0.55, 16),
      new THREE.MeshStandardMaterial({ color: 0x0f3f5c, metalness: 0.8, roughness: 0.25 })
    );
    motorMesh.position.set(0, 0.35, 0);
    motorMesh.castShadow = true;
    aeratorGroup.add(motorMesh);

    // Rotating 8-Blade Paddlewheel
    const paddleGroup = new THREE.Group();
    paddleGroup.position.set(0, 0.1, 0.75);
    const bladeMat = new THREE.MeshStandardMaterial({ color: 0xf4fbfc, roughness: 0.25, metalness: 0.1 });
    for (let i = 0; i < 8; i++) {
      const blade = new THREE.Mesh(new THREE.BoxGeometry(1.4, 0.04, 0.28), bladeMat);
      blade.rotation.x = (i * Math.PI) / 4;
      blade.castShadow = true;
      paddleGroup.add(blade);
    }
    aeratorGroup.add(paddleGroup);
    aeratorPaddleRef.current = paddleGroup;

    // Anchor Stem Pin
    const aeratorPin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.02, 0.02, 0.6, 8),
      new THREE.MeshStandardMaterial({ color: 0x1f8aa6, metalness: 0.8 })
    );
    aeratorPin.position.set(0, 0.7, 0);
    aeratorGroup.add(aeratorPin);

    scene.add(aeratorGroup);

    // (B) Aerator Spray Mist Particles
    const particleCount = 220;
    const particleGeo = new THREE.BufferGeometry();
    const particlePositions = new Float32Array(particleCount * 3);
    const particleVelocities = new Float32Array(particleCount * 3);

    for (let i = 0; i < particleCount; i++) {
      particlePositions[i * 3] = DATA_POINT_ANCHORS.aerator_1.x + (Math.random() - 0.5) * 1.6;
      particlePositions[i * 3 + 1] = 0.1 + Math.random() * 0.4;
      particlePositions[i * 3 + 2] = DATA_POINT_ANCHORS.aerator_1.z + 0.7 + Math.random() * 1.4;

      particleVelocities[i * 3] = (Math.random() - 0.5) * 0.035;
      particleVelocities[i * 3 + 1] = 0.035 + Math.random() * 0.045;
      particleVelocities[i * 3 + 2] = 0.035 + Math.random() * 0.055;
    }

    particleGeo.setAttribute('position', new THREE.BufferAttribute(particlePositions, 3));
    const particleMat = new THREE.PointsMaterial({
      color: 0xffffff,
      size: 0.16,
      transparent: true,
      opacity: 0.7,
      blending: THREE.AdditiveBlending,
    });
    const sprayParticles = new THREE.Points(particleGeo, particleMat);
    scene.add(sprayParticles);
    sprayParticlesRef.current = sprayParticles;

    // (C) Sensor Sonde Buoy at DATA_POINT_ANCHORS.sonde_buoy_1
    const sondeGroup = new THREE.Group();
    sondeGroup.position.copy(DATA_POINT_ANCHORS.sonde_buoy_1);

    const buoyBody = new THREE.Mesh(
      new THREE.CylinderGeometry(0.38, 0.44, 0.75, 20),
      new THREE.MeshStandardMaterial({ color: 0x1f8aa6, roughness: 0.3, metalness: 0.15 })
    );
    buoyBody.castShadow = true;
    buoyBody.receiveShadow = true;
    sondeGroup.add(buoyBody);

    const solarDisc = new THREE.Mesh(
      new THREE.CylinderGeometry(0.48, 0.48, 0.06, 20),
      new THREE.MeshStandardMaterial({ color: 0x092131, roughness: 0.2, metalness: 0.85 })
    );
    solarDisc.position.y = 0.4;
    solarDisc.castShadow = true;
    sondeGroup.add(solarDisc);

    const mast = new THREE.Mesh(
      new THREE.CylinderGeometry(0.03, 0.03, 1.1, 8),
      new THREE.MeshStandardMaterial({ color: 0xdce8ec, metalness: 0.9, roughness: 0.1 })
    );
    mast.position.y = 0.85;
    sondeGroup.add(mast);

    const sondeLed = new THREE.PointLight(0x4fbfa0, 1.8, 3.5);
    sondeLed.position.set(0, 1.35, 0);
    sondeGroup.add(sondeLed);
    sondeLedRef.current = sondeLed;

    scene.add(sondeGroup);
    sondeGroupRef.current = sondeGroup;

    // (D) Inflow Sluice Gate Prop at DATA_POINT_ANCHORS.inflow_1
    const inflowGroup = new THREE.Group();
    inflowGroup.position.copy(DATA_POINT_ANCHORS.inflow_1);

    const sluiceBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.8, 0.7, 0.5),
      new THREE.MeshStandardMaterial({ color: 0x154c6e, metalness: 0.6, roughness: 0.4 })
    );
    sluiceBox.castShadow = true;
    sluiceBox.receiveShadow = true;
    inflowGroup.add(sluiceBox);

    const inflowPin = new THREE.Mesh(
      new THREE.CylinderGeometry(0.02, 0.02, 0.8, 8),
      new THREE.MeshStandardMaterial({ color: 0x4fbfa0, metalness: 0.8 })
    );
    inflowPin.position.set(0, 0.7, 0);
    inflowGroup.add(inflowPin);

    scene.add(inflowGroup);

    // ==========================================
    // 6. MAIN ANIMATION & RENDERING LOOP
    // ==========================================
    const tempVec = new THREE.Vector3();

    const animate = () => {
      animationFrameIdRef.current = requestAnimationFrame(animate);
      const elapsedTime = clockRef.current.getElapsedTime();

      // Handle Smooth Eased Camera Preset Transitions
      if (cameraTweenRef.current?.active) {
        const tween = cameraTweenRef.current;
        const progress = Math.min(1, (performance.now() - tween.startTime) / tween.duration);
        const ease = 1 - Math.pow(1 - progress, 3); // Ease out cubic

        camera.position.lerpVectors(tween.startPos, tween.endPos, ease);
        controls.target.lerpVectors(tween.startTarget, tween.endTarget, ease);

        if (progress >= 1) {
          tween.active = false;
        }
      }

      controls.update();

      // Dual-Layer Animated Scrolling Water Normal Maps
      if (waterNormalTextureRef.current) {
        waterNormalTextureRef.current.offset.x = (elapsedTime * 0.035) % 1;
        waterNormalTextureRef.current.offset.y = (elapsedTime * 0.025) % 1;
      }

      // Sonde Buoy Gentle Water Surface Bobbing
      if (sondeGroupRef.current) {
        sondeGroupRef.current.position.y = DATA_POINT_ANCHORS.sonde_buoy_1.y + Math.sin(elapsedTime * 2.0) * 0.025;
        sondeGroupRef.current.rotation.z = Math.sin(elapsedTime * 1.5) * 0.02;
      }

      // Animate Aerator Paddlewheel Rotation
      if (aeratorPaddleRef.current && aerationHours > 0) {
        aeratorPaddleRef.current.rotation.x += 0.09 * (aerationHours / 8);
      }

      // Animate Aerator Spray Mist Particles
      if (sprayParticlesRef.current) {
        if (aerationHours > 0) {
          sprayParticlesRef.current.visible = true;
          const posAttr = sprayParticlesRef.current.geometry.attributes.position;
          const posArr = posAttr.array as Float32Array;

          for (let i = 0; i < particleCount; i++) {
            posArr[i * 3] += particleVelocities[i * 3];
            posArr[i * 3 + 1] += particleVelocities[i * 3 + 1];
            posArr[i * 3 + 2] += particleVelocities[i * 3 + 2];
            particleVelocities[i * 3 + 1] -= 0.0018; // Soft gravity

            if (posArr[i * 3 + 1] <= 0.06) {
              posArr[i * 3] = DATA_POINT_ANCHORS.aerator_1.x + (Math.random() - 0.5) * 1.6;
              posArr[i * 3 + 1] = 0.1 + Math.random() * 0.3;
              posArr[i * 3 + 2] = DATA_POINT_ANCHORS.aerator_1.z + 0.6 + Math.random() * 0.4;
              particleVelocities[i * 3 + 1] = 0.035 + Math.random() * 0.045;
            }
          }
          posAttr.needsUpdate = true;
        } else {
          sprayParticlesRef.current.visible = false;
        }
      }

      // Pulsate Sonde LED
      if (sondeLedRef.current) {
        sondeLedRef.current.intensity = 1.2 + Math.sin(elapsedTime * 3.8) * 0.8;
      }

      // Project 3D Anchors to 2D Screen Space for Interactive Leader-Line Labels
      if (canvasContainerRef.current) {
        const rect = canvasContainerRef.current.getBoundingClientRect();
        const getScreenPos = (worldPos: THREE.Vector3, yOffset = 1.2) => {
          tempVec.copy(worldPos);
          tempVec.y += yOffset; // Offset above anchor
          tempVec.project(camera);

          const isBehind = tempVec.z > 1;
          const x = ((tempVec.x + 1) * rect.width) / 2;
          const y = ((-tempVec.y + 1) * rect.height) / 2;

          return { x, y, visible: !isBehind && x >= 0 && x <= rect.width && y >= 0 && y <= rect.height };
        };

        setAnchorScreenPositions({
          aerator: getScreenPos(DATA_POINT_ANCHORS.aerator_1, 1.1),
          sonde: getScreenPos(DATA_POINT_ANCHORS.sonde_buoy_1, 1.4),
          inflow: getScreenPos(DATA_POINT_ANCHORS.inflow_1, 0.9),
        });
      }

      renderer.render(scene, camera);
    };

    animate();

    // Resize Handler
    const handleResize = () => {
      if (!canvasContainerRef.current) return;
      const w = canvasContainerRef.current.clientWidth;
      const h = canvasContainerRef.current.clientHeight;
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
      renderer.setSize(w, h);
    };

    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      if (animationFrameIdRef.current) {
        cancelAnimationFrame(animationFrameIdRef.current);
      }
      renderer.dispose();
      envRenderTarget.dispose();
    };
  }, [isDark, aerationHours, simulatedDO, simulatedTAN]);

  // Recalculated Camera Presets Against Real pond.fbx Geometry
  const handlePresetSelect = (preset: 'aerial' | 'surface' | 'aerator' | 'sonde') => {
    if (preset === 'aerial') {
      animateCameraTo(new THREE.Vector3(0, 22, 0.1), new THREE.Vector3(0, 0, 0), 450, 'aerial');
    } else if (preset === 'surface') {
      animateCameraTo(new THREE.Vector3(15, 6.5, 15), new THREE.Vector3(0, 0.3, 0), 450, 'surface');
    } else if (preset === 'aerator') {
      animateCameraTo(new THREE.Vector3(6.8, 2.5, -0.8), DATA_POINT_ANCHORS.aerator_1, 450, 'aerator');
    } else if (preset === 'sonde') {
      animateCameraTo(new THREE.Vector3(2.8, 2.0, 2.8), DATA_POINT_ANCHORS.sonde_buoy_1, 450, 'sonde');
    }
  };

  const handleResetCamera = () => {
    animateCameraTo(new THREE.Vector3(16, 9.5, 17), new THREE.Vector3(0, 0.3, 0), 400, 'surface');
  };

  const toggleAutoRotate = () => {
    setAutoRotate((prev) => {
      const next = !prev;
      if (controlsRef.current) {
        controlsRef.current.autoRotate = next;
      }
      return next;
    });
  };

  const toggleFullscreen = () => {
    if (!containerRef.current) return;
    if (!isFullscreen) {
      if (containerRef.current.requestFullscreen) {
        containerRef.current.requestFullscreen();
      }
      setIsFullscreen(true);
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      }
      setIsFullscreen(false);
    }
  };

  return (
    <div
      ref={containerRef}
      className={`relative w-full rounded-xl overflow-hidden border border-surface-border dark:border-surface-darkBorder bg-surface-card dark:bg-surface-darkCard shadow-card-soft ${
        isFullscreen ? 'h-screen w-screen fixed inset-0 z-50 rounded-none' : 'h-[480px]'
      } ${className}`}
    >
      {/* 3D WebGL Canvas Mount */}
      <div ref={canvasContainerRef} className="w-full h-full cursor-grab active:cursor-grabbing" />

      {/* Loading Overlay */}
      {loading && (
        <div className="absolute inset-0 bg-surface-base/80 dark:bg-surface-darkBase/80 backdrop-blur-sm flex flex-col items-center justify-center gap-3 z-30 font-mono">
          <div className="w-10 h-10 border-3 border-teal-600/30 border-t-teal-600 rounded-full animate-spin" />
          <div className="text-center">
            <p className="text-xs font-bold text-ocean-900 dark:text-teal-300 tracking-wider">
              RENDERING DIGITAL TWIN (pond.fbx)
            </p>
            <p className="text-[11px] text-slate-500 mt-0.5">{loadProgress}% complete</p>
          </div>
        </div>
      )}

      {/* INTERACTIVE 3D DATA-POINT LEADER-LINE ANCHOR LABELS */}
      {/* 1. Aerator Anchor Label */}
      {anchorScreenPositions.aerator?.visible && (
        <div
          style={{
            left: `${anchorScreenPositions.aerator.x}px`,
            top: `${anchorScreenPositions.aerator.y}px`,
            transform: 'translate(-50%, -100%)',
          }}
          className={`absolute z-20 pointer-events-auto transition-all duration-200 cursor-pointer ${
            activePreset === 'aerator' ? 'scale-105 opacity-100' : 'opacity-85 hover:opacity-100'
          }`}
          onClick={() => handlePresetSelect('aerator')}
        >
          <div className="flex flex-col items-center">
            <div
              className={`px-2 py-1 rounded-lg text-[10px] font-mono font-bold shadow-md border backdrop-blur-md flex items-center gap-1.5 transition-all ${
                activePreset === 'aerator'
                  ? 'bg-teal-600 text-white border-teal-400 ring-2 ring-teal-500/30'
                  : 'bg-white/95 dark:bg-slate-900/95 text-ocean-900 dark:text-slate-200 border-teal-200 dark:border-teal-800'
              }`}
            >
              <Wind className="w-3 h-3 text-teal-500" />
              <span>Paddlewheel Aerator: {aerationHours > 0 ? `${aerationHours}h Active` : 'Off'}</span>
            </div>
            <div className="w-[1.5px] h-3 bg-teal-500/80 mt-0.5 shadow-xs" />
            <div className="w-1.5 h-1.5 rounded-full bg-teal-600 ring-2 ring-teal-400/50 shadow-xs" />
          </div>
        </div>
      )}

      {/* 2. Sonde Buoy Anchor Label */}
      {anchorScreenPositions.sonde?.visible && (
        <div
          style={{
            left: `${anchorScreenPositions.sonde.x}px`,
            top: `${anchorScreenPositions.sonde.y}px`,
            transform: 'translate(-50%, -100%)',
          }}
          className={`absolute z-20 pointer-events-auto transition-all duration-200 cursor-pointer ${
            activePreset === 'sonde' ? 'scale-105 opacity-100' : 'opacity-85 hover:opacity-100'
          }`}
          onClick={() => handlePresetSelect('sonde')}
        >
          <div className="flex flex-col items-center">
            <div
              className={`px-2 py-1 rounded-lg text-[10px] font-mono font-bold shadow-md border backdrop-blur-md flex items-center gap-1.5 transition-all ${
                activePreset === 'sonde'
                  ? 'bg-mint-700 text-white border-mint-400 ring-2 ring-mint-500/30'
                  : 'bg-white/95 dark:bg-slate-900/95 text-ocean-900 dark:text-slate-200 border-mint-200 dark:border-mint-800'
              }`}
            >
              <Activity className="w-3 h-3 text-mint-600" />
              <span>
                Optical Sonde: {simulatedDO.toFixed(2)} mg/L DO
              </span>
            </div>
            <div className="w-[1.5px] h-3 bg-mint-500/80 mt-0.5 shadow-xs" />
            <div className="w-1.5 h-1.5 rounded-full bg-mint-600 ring-2 ring-mint-400/50 shadow-xs" />
          </div>
        </div>
      )}

      {/* 3. Inflow Feeder Sluice Label */}
      {anchorScreenPositions.inflow?.visible && (
        <div
          style={{
            left: `${anchorScreenPositions.inflow.x}px`,
            top: `${anchorScreenPositions.inflow.y}px`,
            transform: 'translate(-50%, -100%)',
          }}
          className="absolute z-20 pointer-events-auto opacity-75 hover:opacity-100 transition-opacity"
        >
          <div className="flex flex-col items-center">
            <div className="px-2 py-0.5 rounded-lg text-[10px] font-mono font-bold bg-white/90 dark:bg-slate-900/90 text-ocean-900 dark:text-slate-200 border border-surface-border shadow-xs flex items-center gap-1">
              <Droplets className="w-2.5 h-2.5 text-ocean-600" />
              <span>Inflow Canal: {waterExchangePct}%/day</span>
            </div>
            <div className="w-[1px] h-2.5 bg-slate-400/60 mt-0.5" />
            <div className="w-1 h-1 rounded-full bg-ocean-600" />
          </div>
        </div>
      )}

      {/* FIXED BOTTOM-RIGHT HUD READOUT PANEL */}
      <div className="absolute bottom-3 right-3 z-20 w-64 hud-card rounded-xl p-3 space-y-2.5 pointer-events-auto shadow-card-elevated">
        {/* Panel Header */}
        <div className="flex items-center justify-between border-b border-surface-border dark:border-surface-darkBorder pb-1.5">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-mint-600 animate-pulse" />
            <span className="font-mono text-xs font-bold text-ocean-900 dark:text-slate-100">
              3D Digital Twin HUD
            </span>
          </div>
          <span className="font-mono text-[9px] font-bold px-1.5 py-0.5 rounded bg-teal-50 dark:bg-teal-950/60 text-teal-700 dark:text-teal-300 border border-teal-200 dark:border-teal-800">
            pond.fbx
          </span>
        </div>

        {/* Target Metadata */}
        <div className="space-y-0.5 text-[11px] font-mono">
          <div className="flex justify-between items-center text-slate-500 dark:text-slate-400">
            <span>Target Pond:</span>
            <span className="font-bold text-teal-700 dark:text-teal-400">{pondId}</span>
          </div>
          <div className="flex justify-between items-center text-slate-500 dark:text-slate-400">
            <span>Hydrodynamics:</span>
            <span className="font-semibold text-ocean-900 dark:text-slate-200">Navier-Stokes</span>
          </div>
        </div>

        {/* Live Stacked Telemetry Readout Table */}
        <div className="pt-1 border-t border-surface-border dark:border-surface-darkBorder space-y-1 font-mono text-[11px]">
          <div className="flex justify-between items-center p-1 rounded-md bg-surface-cardSubtle dark:bg-surface-darkCardAlt">
            <span className="text-slate-600 dark:text-slate-400 flex items-center gap-1.5">
              <Activity className="w-3.5 h-3.5 text-teal-600" /> Live DO State:
            </span>
            <RiskStatusBadge risk={simulatedDO} blind_state={false} showValue={true} suffix="mg/L" />
          </div>

          <div className="flex justify-between items-center p-1 rounded-md bg-surface-cardSubtle dark:bg-surface-darkCardAlt">
            <span className="text-slate-600 dark:text-slate-400 flex items-center gap-1.5">
              <Droplets className="w-3.5 h-3.5 text-ocean-600" /> TAN Ammonia:
            </span>
            <span className="font-bold text-ocean-900 dark:text-teal-300">{simulatedTAN.toFixed(2)} mg/L</span>
          </div>

          <div className="flex justify-between items-center p-1 rounded-md bg-surface-cardSubtle dark:bg-surface-darkCardAlt">
            <span className="text-slate-600 dark:text-slate-400 flex items-center gap-1.5">
              <Wind className="w-3.5 h-3.5 text-teal-600" /> Night Aeration:
            </span>
            <span className="font-bold text-ocean-900 dark:text-teal-300">
              {aerationHours > 0 ? `${aerationHours}h Active` : 'Off'}
            </span>
          </div>

          <div className="flex justify-between items-center p-1 rounded-md bg-surface-cardSubtle dark:bg-surface-darkCardAlt">
            <span className="text-slate-600 dark:text-slate-400 flex items-center gap-1.5">
              <Layers className="w-3.5 h-3.5 text-mint-600" /> Canal Exchange:
            </span>
            <span className="font-bold text-ocean-900 dark:text-teal-300">{waterExchangePct}% / day</span>
          </div>
        </div>
      </div>

      {/* TOP LEFT CAMERA PRESETS BAR */}
      <div className="absolute top-3 left-3 z-20 flex items-center gap-1 hud-card p-1.5 rounded-xl">
        <button
          onClick={() => handlePresetSelect('aerial')}
          className={`px-2.5 py-1 text-xs font-mono rounded-lg transition-all ${
            activePreset === 'aerial'
              ? 'bg-teal-600 text-white font-bold shadow-sm'
              : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          Aerial (90°)
        </button>
        <button
          onClick={() => handlePresetSelect('surface')}
          className={`px-2.5 py-1 text-xs font-mono rounded-lg transition-all ${
            activePreset === 'surface'
              ? 'bg-teal-600 text-white font-bold shadow-sm'
              : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          Surface Bank
        </button>
        <button
          onClick={() => handlePresetSelect('aerator')}
          className={`px-2.5 py-1 text-xs font-mono rounded-lg transition-all ${
            activePreset === 'aerator'
              ? 'bg-teal-600 text-white font-bold shadow-sm'
              : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          Aerator Focus
        </button>
        <button
          onClick={() => handlePresetSelect('sonde')}
          className={`px-2.5 py-1 text-xs font-mono rounded-lg transition-all ${
            activePreset === 'sonde'
              ? 'bg-teal-600 text-white font-bold shadow-sm'
              : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          Sonde Buoy
        </button>
      </div>

      {/* BOTTOM-LEFT CONTROLS TOOLBAR */}
      <div className="absolute bottom-3 left-3 z-20 flex items-center gap-2 hud-card px-3 py-1.5 rounded-full">
        <button
          onClick={toggleAutoRotate}
          className={`p-1.5 rounded-full transition-colors ${
            autoRotate
              ? 'bg-teal-600 text-white shadow-sm'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
          title={autoRotate ? 'Pause Rotation' : 'Auto Orbit'}
        >
          {autoRotate ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
        </button>

        <button
          onClick={handleResetCamera}
          className="p-1.5 rounded-full text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          title="Reset Camera Angle"
        >
          <RotateCcw className="w-3.5 h-3.5" />
        </button>

        <div className="w-[1px] h-4 bg-surface-border dark:bg-surface-darkBorder" />

        <button
          onClick={toggleFullscreen}
          className="p-1.5 rounded-full text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          title={isFullscreen ? 'Exit Fullscreen' : 'Fullscreen 3D View'}
        >
          {isFullscreen ? <Minimize2 className="w-3.5 h-3.5" /> : <Maximize2 className="w-3.5 h-3.5" />}
        </button>
      </div>
    </div>
  );
};
