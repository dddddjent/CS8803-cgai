'use client';

import { Suspense, useRef } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import * as THREE from 'three';

import vertexShader from '@/shaders/common/vertex.glsl';
import fragmentShader from './fragment.glsl';

const HW1 = ({ dpr }: { dpr: number }) => {
    const { viewport, pointer } = useThree();
    const uniforms = useRef({
        uTime: { value: 0 },
        uResolution: {
            value: new THREE.Vector2(window.innerWidth * dpr, window.innerHeight * dpr),
        },
        uFrame: { value: 0 },
        uMouse: { value: new THREE.Vector2(0, 0) },
        uLightTheta: { value: 0 },
        uLightRotationMat: { value: new THREE.Matrix4() },
        larmTransform: {
            value: new THREE.Matrix4()
                .multiplyMatrices(
                    new THREE.Matrix4().makeTranslation(0.05, 0.75, 0),
                    new THREE.Matrix4().makeRotationX(-Math.PI / 4),
                )
                .multiply(new THREE.Matrix4().makeScale(1.0, 2.0, 1.0))
                .invert(),
        },
        rarmTransform: {
            value: new THREE.Matrix4()
                .multiplyMatrices(
                    new THREE.Matrix4().makeTranslation(0.05, 0.75, -1.0),
                    new THREE.Matrix4().makeRotationX(Math.PI / 4),
                )
                .multiply(new THREE.Matrix4().makeScale(1.0, 2.0, 1.0))
                .invert(),
        },
        llegTransform: {
            value: new THREE.Matrix4()
                .multiplyMatrices(
                    new THREE.Matrix4().makeTranslation(0.05, -0.25, -0.2),
                    new THREE.Matrix4().makeRotationX(-Math.PI / 8),
                )
                .multiply(new THREE.Matrix4().makeScale(1.3, 3.5, 1.3))
                .invert(),
        },
        rlegTransform: {
            value: new THREE.Matrix4()
                .multiplyMatrices(
                    new THREE.Matrix4().makeTranslation(0.05, -0.25, -0.8),
                    new THREE.Matrix4().makeRotationX(Math.PI / 8),
                )
                .multiply(new THREE.Matrix4().makeScale(1.3, 3.5, 1.3))
                .invert(),
        },
        headTransform: {
            value: new THREE.Matrix4()
                .multiplyMatrices(
                    new THREE.Matrix4().makeTranslation(0, 0, 0),
                    new THREE.Matrix4().makeRotationX(0),
                )
                .multiply(new THREE.Matrix4().makeScale(1.0, 1.0, 1.0))
                .invert(),
        }
    }).current;

    useFrame((_, delta) => {
        uniforms.uTime.value += delta;
        uniforms.uResolution.value.set(window.innerWidth * dpr, window.innerHeight * dpr);
        uniforms.uFrame.value += 1;
        uniforms.uMouse.value.set(pointer.x, pointer.y);
        uniforms.uLightTheta.value += delta;
        uniforms.uLightRotationMat.value.makeRotationFromEuler(new THREE.Euler(0, uniforms.uLightTheta.value, 0));
    });

    return (
        <mesh scale={[viewport.width, viewport.height, 1]}>
            <planeGeometry args={[1, 1]} />
            <shaderMaterial
                fragmentShader={fragmentShader}
                vertexShader={vertexShader}
                uniforms={uniforms}
            />
        </mesh>
    );
};

export default function TestPage() {
    const dpr = 1;
    return (
        <Canvas
            orthographic
            dpr={dpr}
            camera={{ position: [0, 0, 6] }}
            style={{
                position: 'fixed',
                top: 0,
                left: 0,
                width: '100vw',
                height: '100vh',
            }}
        >
            <Suspense fallback={null}>
                <HW1 dpr={dpr} />
            </Suspense>
        </Canvas>
    );
}
