//
//  MetalView.swift
//  MetalDemo
//
//  Created by Saheem Hussain on 26/09/23.
//

import Foundation
import MetalKit
//MetalKit for using Model I/O with Metal
//Provides utilities to efficiently load Model assets using Model I/O directly into metal buffers and textures. Provides container structures for renderable meshes and submeshes.

class MetalView: UIView {
    
    //MARK: - Properties
    
    private var metalView : MTKView!
    private var device: MTLDevice!
    private var commandQueue : MTLCommandQueue!
    private var metalRenderPipelineState : MTLRenderPipelineState!
    private var mesh: MTKMesh!
    
    public required init() {
        super.init(frame: .zero)
        setupView()
        setupMetal()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    //MARK: - Methods
    
    fileprivate func setupView(){
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    fileprivate func setupMetal(){
        //configures an MTKView for the Metal renderer
        metalView = MTKView()
        addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        metalView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        metalView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        metalView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        metalView.delegate = self
        
        //This tells MTKView that it should be paused and should wait for us to tell it when it needs to display something.
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        
        //connect to the gpu
        setupDevice()
        metalView.device = device
        
        createCommandQueue()
        setUpCircleModel()
        setupPipelineState()
        
        //draw
        metalView.setNeedsDisplay()
    }
    
    //This function checks for a suitable GPU by creating a device
    func setupDevice() {
        //interface for gpu
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("GPU is not supported")
            return
        }
        
        self.device = device
    }
    
    func createCommandQueue() {
        guard let commandQueue = device.makeCommandQueue() else {
            print("Could not make a command queue")
            return
        }
        self.commandQueue = commandQueue
    }
    
    func setUpCircleModel() {
        
        //method to load vertex and index data directly into Metal buffers.
        let allocator = MTKMeshBufferAllocator(device: device) //manages the memory for the mesh data
        
        //Primitive
        //Model I/O creates a sphere with the specified size and returns an MDLMesh with all the vertex information in data buffers.
        let mdlMesh = MDLMesh(sphereWithExtent: [0.75,0.75,0.75],
                              segments: [100, 100],
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        
        do {
            //For Metal to be able to use the mesh, you convert it from a Model I/O mesh to a MetalKit mesh.
            let mesh = try MTKMesh(mesh: mdlMesh, device: device)
            self.mesh = mesh
        } catch (let error) {
            print(error)
        }
    }
    
    func setupPipelineState() {
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        //finds the metal file from the main bundle
        let library = device.makeDefaultLibrary()
        
        guard let library else {
            print("No metal file found")
            return
        }
        //The compiler will check that these functions exist and make them available to a pipeline descriptor.
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        //set the pixel format to match the MetalView's pixel format
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        if let mesh = self.mesh {
            //describe to the GPU how the vertices are laid out in memory using a vertex descriptor
            pipelineDescriptor.vertexDescriptor =
            MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        }
        do {
            metalRenderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch (let error) {
            print(error)
        }
        
    }
}

//MARK: - Extension
extension MetalView : MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //not worried about this
    }
    
    //delegate method that runs every frame
    func draw(in view: MTKView) {
        
        //Creating the commandBuffer for the queue. This stores all the commands that you’ll ask the GPU to run.
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        
        //Creating the interface for the pipeline
        ///The descriptor holds data for the render destinations, known as attachments. Each attachment needs information, such as a texture to store to, and whether to keep the texture throughout the render pass. The render pass descriptor is used to create the render command encoder.
        guard let renderDescriptor = view.currentRenderPassDescriptor else {return}
        
        //Setting a "background color"
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 0.8 , 1)
        
        //Creating the command encoder, or the "inside" of the pipeline
        //The render command encoder holds all the information necessary to send to the GPU so that it can draw the vertices.
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else {return}
        
        //********* We'll be encoding commands here **************//
        renderEncoder.setRenderPipelineState(metalRenderPipelineState)
        
        //The sphere mesh that you loaded earlier holds a buffer containing a simple list of vertices. Give this buffer to the render encoder.
        
        ///The offset is the position in the buffer where the vertex information starts.
        ///The index is how the GPU vertex shader function locates this buffer.
        renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        
        guard let submesh = mesh.submeshes.first else {
            fatalError()
        }
        
//        This code tells the GPU to render lines instead of solid triangles.
        renderEncoder.setTriangleFillMode(.lines)
        
        //Here, you’re instructing the GPU to render a vertex buffer consisting of triangles with the vertices placed in the correct order by the submesh index information. This code does not do the actual render — that doesn’t happen until the GPU has received all the command buffer’s commands
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: 0)
        
        
        //Complete sending commands to the render command encoder and finalize the frame
        
        //You tell the render encoder that there are no more draw calls and end the render pass.
        renderEncoder.endEncoding()
        ///We can use the MTKView’s currentDrawable, a drawable representing the current frame
        guard let drawable = view.currentDrawable else {
            fatalError()
        }
        //Ask the command buffer to present the MTKView’s drawable and commit to the GPU.
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
}
