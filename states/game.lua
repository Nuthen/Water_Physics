game = {}

function game:enter()
    self.segments = 200

    self.k = 0.025-- k/m
    self.damping = 0.0025

    self.targetHeight = 0.5
    self.spreadPasses = 8
    self.spreadAmount = 0.3

    self.objectDamping = 0.97
    self.objectHorizontalSpeed = 10000

    self.gravity = 80

    self.waves = {}
    for i = 1, self.segments + 1 do
        self.waves[i] = {position=self.targetHeight, velocity=0, acceleration=-self.k * self.targetHeight}
    end

    self.objects = {}
end

function game:splash(index, speed)
    if index >= 1 and index <= #self.waves then
        self.waves[index].velocity = speed
    end
end

function game:update(dt)
    for i = 1, #self.waves do
        local acceleration = -self.k * (self.waves[i].position - self.targetHeight) - self.damping * self.waves[i].velocity

        self.waves[i].position = self.waves[i].position + self.waves[i].velocity * dt
        self.waves[i].velocity = self.waves[i].velocity + acceleration
    end

    local leftDeltas = {}
    local rightDeltas = {}

    for i = 1, self.spreadPasses do
        for j = 1, #self.waves do
            if j > 1 then
                leftDeltas[j] = self.spreadAmount * (self.waves[j].position - self.waves[j-1].position)
                self.waves[j-1].velocity = self.waves[j-1].velocity + leftDeltas[j]
            end
            if j < #self.waves then
                rightDeltas[j] = self.spreadAmount * (self.waves[j].position - self.waves[j+1].position)
                self.waves[j+1].velocity = self.waves[j+1].velocity + rightDeltas[j]
            end
        end
    end

    for j = 1, #self.waves do
        if j > 1 then
            self.waves[j-1].position = self.waves[j-1].position + leftDeltas[j]
         end
        if j < #self.waves then
            self.waves[j+1].position = self.waves[j+1].position + rightDeltas[j]
        end
    end

    for k, object in pairs(self.objects) do
        object.y = object.y + object.velocity*dt
        object.velocity = (object.velocity + object.grav) * self.objectDamping

        local closest = 1
        for i = 2, #self.waves do
            if math.abs(object.x - (love.graphics.getWidth()/self.segments) * (i-1)) <= (love.graphics.getWidth()/self.segments)/2 then
                closest = i
            end
        end

        local leftGreater, rightGreater = false, false

        if closest > 1 then
            if self.waves[closest-1].position > self.waves[closest].position then
                leftGreater = true
            end
        end
        if closest < #self.waves then
            if self.waves[closest+1].position > self.waves[closest].position then
                rightGreater = true
            end
        end

        local speed = self.objectHorizontalSpeed * dt

        if object.y/love.graphics.getHeight() > self.waves[closest].position then
            if leftGreater and rightGreater then
                if self.waves[closest-1].position > self.waves[closest+1].position then
                    object.x = object.x - speed * (self.waves[closest].position-self.waves[closest-1].position)
                else
                    object.x = object.x + speed * (self.waves[closest].position-self.waves[closest-1].position)
                end
            elseif leftGreater then
                object.x = object.x - speed * (self.waves[closest].position-self.waves[closest+1].position)
            elseif rightGreater then
                object.x = object.x + speed * (self.waves[closest].position-self.waves[closest+1].position)
            end
        end


        if object.y/love.graphics.getHeight() + .05 < self.waves[closest].position and math.abs(object.grav) < 0.001 then
            object.grav = self.gravity
        elseif object.y/love.graphics.getHeight() > self.waves[closest].position then
            if not object.hasSplashed then
                self:splash(closest, object.velocity/love.graphics.getHeight())
                object.hasSplashed = true
            elseif object.heading == "down" then
                object.heading = "up"
                object.grav = -object.grav/2
            end
        else
            if object.heading == "up" then
                object.heading = "down"
                object.grav = -object.grav/2
            end
        end
    end
end

function game:keypressed(key, code)

end

function game:mousepressed(x, y, mbutton)
    table.insert(self.objects, {x=x, y=y,velocity=0,grav=self.gravity,hasSplashed=false,heading="down"})
end

function game:draw()
    love.graphics.setBackgroundColor(255, 255, 255)
    love.graphics.setColor(0, 0, 255)

    for i = 1, #self.waves - 1 do
        local x1, y1 = (love.graphics.getWidth()/self.segments) * (i-1), love.graphics.getHeight() * self.waves[i].position
        local x2, y2 = (love.graphics.getWidth()/self.segments) * (i), love.graphics.getHeight() * self.waves[i+1].position
        love.graphics.polygon("fill", x1, y1, x2, y2, x2, love.graphics.getHeight(), x1, love.graphics.getHeight())
    end

    love.graphics.setColor(0, 255, 0)
    for k, object in pairs(self.objects) do
        love.graphics.circle("fill", object.x, object.y, 20)
    end
end
