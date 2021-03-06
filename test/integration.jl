using Cellular, Dispersal, Test


@testset "dispersal kernel array matches passed in function" begin
    init = [0 1 0; 
            1 0 1]
    dk = DispersalKernel(f=exponential, cellsize=1, init=init, radius=2, param=(1.0,)).kernel

    @test size(dk) == (5, 5)
    @test sum(dk) ≈ 1.0
end

@testset "binary dispersal and suitability mask" begin
    init = [0 0; 
            0 1]
    hood = DispersalKernel(; radius=1)
    # sequence of layers
    suitseq = Sequence(([0.1 0.2; 
                         0.3 0.4], 
                        [0.5 0.6; 
                         0.7 0.8]), 
                       10);
    model = Models(InwardsBinaryDispersal(neighborhood=hood, prob_threshold=0.0), 
                          SuitabilityMask(layers=suitseq, threshold=0.4))
    output = ArrayOutput(init, 25)

    @test Dispersal.pressure(model.models[1], init, 1) 

    sim!(output, model, init; tstop=25)

    # All offset by one, because 1 = t0
    @test output[1]  == [0 0; 0 1]
    @test output[2]  == [0 0; 1 1]
    @test output[5]  == [0 0; 0 1]
    @test output[8]  == [0 0; 1 1]
    @test output[10] == [0 1; 1 1]
    @test output[15] == [1 1; 1 1]
    @test output[20] == [0 1; 1 1]
    @test output[22] == [0 0; 1 1]
    @test output[25] == [0 0; 0 1]
    @test_throws BoundsError output[26]
end


@testset "binary dispersal simulation with suitability mask" begin

    suit =  [1 0 1 1 0;
             0 0 1 1 1;
             1 1 1 1 0;
             1 1 0 1 1;
             1 0 1 1 1]

    init =  Bool[0 0 0 0 0;
                 0 0 0 0 0;
                 0 0 1 0 0;
                 0 0 0 0 0;
                 0 0 0 0 0]

    test1 = Bool[0 0 0 0 0;
                 0 0 0 0 0;
                 0 0 1 0 0;
                 0 0 0 0 0;
                 0 0 0 0 0]

    test2 = Bool[0 0 0 0 0;
                 0 0 1 1 0;
                 0 1 1 1 0;
                 0 1 0 1 0;
                 0 0 0 0 0]

    test3 = Bool[0 0 1 1 0;
                 0 0 1 1 1;
                 1 1 1 1 0;
                 1 1 0 1 1;
                 1 0 1 1 1]

    # Dispersal in radius 1 neighborhood
    suitmask = SuitabilityMask(layers=suit)
    hood = DispersalKernel(; init=init, radius=1)

    @testset "inwards binary dispersal fills the grid where reachable and suitable" begin
        inwards = InwardsBinaryDispersal(neighborhood=hood, prob_threshold=0.0)
        model = Models(inwards, suitmask)
        output = ArrayOutput(init, 3)
        sim!(output, model, init; tstop=3)
        @test output[1] == test1
        @test output[2] == test2
        @test output[3] == test3

        # As submodels
        model = Models((inwards, suitmask))
        sim!(output, model, init; tstop=3)
        @test output[1] == test1
        @test output[2] == test2
        @test output[3] == test3
    end
    @testset "outwards dispersal fills the grid where reachable and suitable" begin
        outwards = OutwardsBinaryDispersal(neighborhood=hood, prob_threshold=0.0)
        model = Models(outwards, suitmask)
        output = ArrayOutput(init, 3)
        sim!(output, model, init; tstop=3)
        @test output[1] == test1
        @test output[2] == test2
        @test output[3] == test3
    end

end

@testset "floating point population dispersal simulation with suitability mask" begin

    suit =  [1.0 0.0 1.0 0.0 1.0 1.0 0.0;
             1.0 1.0 0.0 0.0 1.0 1.0 1.0;
             1.0 0.0 1.0 1.0 1.0 1.0 0.0;
             1.0 0.0 1.0 1.0 0.0 1.0 1.0;
             1.0 1.0 1.0 0.0 1.0 1.0 1.0;
             1.0 0.0 0.0 0.0 0.0 0.0 0.0;
             1.0 1.0 1.0 1.0 1.0 1.0 1.0]

    init =  [100.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0 100.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0]

    test1 = [100.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0 100.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0;
             0.0 0.0 0.0 0.0   0.0 0.0 0.0]

    test2 = [4.0  0.0  8.0  0.0  4.0  4.0  0.0;
             4.0  4.0  0.0  0.0  4.0  4.0  4.0;
             4.0  0.0  8.0  4.0  4.0  4.0  0.0;
             0.0  0.0  4.0  4.0  0.0  4.0  4.0;
             0.0  0.0  4.0  0.0  4.0  4.0  4.0;
             0.0  0.0  0.0  0.0  0.0  0.0  0.0;
             0.0  0.0  0.0  0.0  0.0  0.0  0.0]

    test3 = [1.28  0.0   1.92  0.0   1.92  1.28  0.0;
             1.44  1.76  0.0   0.0   2.56  1.76  1.44;
             1.6   0.0   2.56  2.88  3.2   2.24  0.0;
             1.12  0.0   1.92  2.24  0.0   1.92  1.6;
             0.8   1.12  1.44  0.0   2.08  1.44  1.12;
             0.32  0.0   0.0   0.0   0.0   0.0   0.0;
             0.16  0.16  0.32  0.48  0.64  0.48  0.48;]

    # Dispersal in radius 1 neighborhood
    suitmask = SuitabilityMask(layers=suit)
    r = 2

    @testset "inwards population dispersal fills the grid where reachable suitable" begin
        hood = DispersalKernel(; f=(d,a)->1.0, radius=r)
        inwards = InwardsPopulationDispersal(neighborhood=hood)
        model = Models(inwards, suitmask)
        output = ArrayOutput(init, 3)
        sim!(output, model, init; tstop=3)
        @test output[1] == test1
        @test output[2] == test2
        @test output[3] ≈ test3

        # As submodels
        model = Models((inwards, suitmask))
        sim!(output, model, init; tstop=3)
        @test output[1] == test1
        @test output[2] == test2
        @test output[3] ≈ test3
    end

    @testset "outwards population dispersal fills the grid where reachable and suitable" begin
        hood = DispersalKernel(; f=(d,a)->1.0, radius=r)
        outwards = OutwardsPopulationDispersal(neighborhood=hood)
        model = Models(outwards, suitmask)
        output = ArrayOutput(init, 3)
        sim!(output, model, init; tstop=3)
        @test output[1] == test1
        @test output[2] == test2
        @test output[3] ≈ test3
    end
end
