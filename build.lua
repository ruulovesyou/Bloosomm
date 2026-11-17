-- Blossom single-file builder.
-- Primary runner: lune run build.lua
-- For the checked-out library source: lune run build.lua --local
-- A plain Luau host must provide an HTTP function (request/http_request) and
-- either writefile or io.open; Luau itself has no portable network API.

local REPOSITORY = "ruulovesyou/Bloosomm"
local BRANCH = "main"
local ROOT = "Blossom/"
local RAW = "https://raw.githubusercontent.com/" .. REPOSITORY .. "/" .. BRANCH .. "/"
local TREE = "https://api.github.com/repos/" .. REPOSITORY .. "/git/trees/" .. BRANCH .. "?recursive=1"

local function optionalRequire(name)
    local ok, value = pcall(require, name)
    return if ok then value else nil
end

local luneNet = optionalRequire("@lune/net")
local luneFs = optionalRequire("@lune/fs")
local luneSerde = optionalRequire("@lune/serde")
local luneProcess = optionalRequire("@lune/process")
local useLocal = luneProcess and table.find(luneProcess.args, "--local") ~= nil
local localRoot = "Bloosoom UI Library/Source/Blossom"

local function decodeJson(body)
    if luneSerde then return luneSerde.decode("json", body) end
    local httpService = _G.game and _G.game:GetService("HttpService")
    if httpService then return httpService:JSONDecode(body) end
    error("No JSON decoder available; run with Lune or provide HttpService")
end

local function httpGet(url)
    if luneNet then
        local response = luneNet.request({url = url, method = "GET"})
        assert(response.statusCode >= 200 and response.statusCode < 300,
            "GET " .. url .. " failed with HTTP " .. tostring(response.statusCode))
        return response.body
    end

    local httpService = _G.game and _G.game:GetService("HttpService")
    if httpService then return httpService:GetAsync(url) end

    local requester = _G.request or _G.http_request
    if requester then
        local response = requester({Url = url, Method = "GET"})
        assert(response.StatusCode >= 200 and response.StatusCode < 300,
            "GET " .. url .. " failed with HTTP " .. tostring(response.StatusCode))
        return response.Body
    end

    error("No HTTP client available; run with Lune or provide request/http_request")
end

local function localRead(path)
    assert(luneFs, "--local requires the Lune filesystem API")
    return luneFs.readFile(path)
end

local function discoverLocal(directory, prefix, output)
    for _, entry in ipairs(luneFs.readDir(directory)) do
        local path = directory .. "/" .. entry.name
        local relative = prefix .. entry.name
        if entry.isDir then
            discoverLocal(path, relative .. "/", output)
        elseif entry.name:sub(-5) == ".luau" then
            table.insert(output, "Blossom/" .. relative)
        end
    end
end

local function writeFile(path, contents)
    if luneFs then
        luneFs.writeFile(path, contents)
        return
    end
    if _G.writefile then
        _G.writefile(path, contents)
        return
    end
    local file = assert(io and io.open(path, "wb"), "No filesystem writer available")
    file:write(contents)
    file:close()
end

local paths = {}
if useLocal then
    discoverLocal(localRoot, "", paths)
else
    local tree = decodeJson(httpGet(TREE))
    for _, entry in ipairs(tree.tree or {}) do
        if entry.type == "blob" and entry.path:sub(1, #ROOT) == ROOT and entry.path:sub(-5) == ".luau" then
            table.insert(paths, entry.path)
        end
    end
end
table.sort(paths)
assert(#paths > 0, "No Luau modules found under " .. ROOT)

local modules = {}
local initSource = nil

for _, path in ipairs(paths) do
    local relative = path:sub(#ROOT + 1, -6)
    local source = if useLocal then localRead(localRoot .. "/" .. relative .. ".luau") else httpGet(RAW .. path)
    if relative == "init" then
        initSource = source
    else
        local folder, name = relative:match("^([^/]+)/([^/]+)$")
        if not folder then
            folder = nil
            name = relative
        end
        table.insert(modules, {
            path = path,
            relative = relative,
            folder = folder,
            name = name,
            source = source,
        })
    end
end

assert(initSource, "Blossom/init.luau was not found")

-- Deterministic ordering: Core first, then Themes, then Components, alphabetical within
local orderRank = {Core = 1, Themes = 2, Components = 3}
table.sort(modules, function(a, b)
    local rankA = orderRank[a.folder] or 99
    local rankB = orderRank[b.folder] or 99
    if rankA ~= rankB then return rankA < rankB end
    if a.folder ~= b.folder then return (a.folder or "") < (b.folder or "") end
    return a.name < b.name
end)

local chunks = {
    "-- Blossom UI Library - single-file bundle (generated)\n",
    "-- Recreates the script.Core / script.Components / script.Themes tree so the\n",
    "-- original require(script.Parent...) paths work under loadstring.\n\n",
    "local function __node(name, parent)\n",
    "    local node = {Name = name, Parent = parent, _children = {}}\n",
    "    return setmetatable(node, {__index = function(_, key) return node._children[key] end})\n",
    "end\n\n",
    "local __root = __node(\"Blossom\", nil)\n\n",
    "local function __register(folder, name, factory)\n",
    "    local parent = __root\n",
    "    if folder then\n",
    "        parent = __root._children[folder]\n",
    "        if not parent then\n",
    "            parent = __node(folder, __root)\n",
    "            __root._children[folder] = parent\n",
    "        end\n",
    "    end\n",
    "    local leaf = __node(name, parent)\n",
    "    leaf._factory = factory\n",
    "    parent._children[name] = leaf\n",
    "end\n\n",
    "local function __require(node)\n",
    "    if type(node) ~= \"table\" or not node._factory then\n",
    "        error(\"Blossom bundle: require target is not a module\", 2)\n",
    "    end\n",
    "    if not node._loaded then\n",
    "        node._result = node._factory(node, __require)\n",
    "        node._loaded = true\n",
    "    end\n",
    "    return node._result\n",
    "end\n\n",
}

for _, module in ipairs(modules) do
    if module.folder then
        table.insert(chunks, string.format('__register("%s", "%s", function(script, require)\n', module.folder, module.name))
    else
        table.insert(chunks, string.format('__register(nil, "%s", function(script, require)\n', module.name))
    end
    table.insert(chunks, module.source)
    table.insert(chunks, "\nend)\n\n")
end

table.insert(chunks, "local function __init(script, require)\n")
table.insert(chunks, initSource)
table.insert(chunks, "\nend\n\nreturn __init(__root, __require)\n")

local output = table.concat(chunks)

if useLocal then
    local dest1 = "Bloosoom UI Library/Source/Blossom/Blossom.lua"
    local dest2 = "Bloosoom UI Library/Blossom.lua"
    writeFile(dest1, output)
    writeFile(dest2, output)
    print(string.format("built local bundles:\n  %s\n  %s\n  %d bytes, %d modules", dest1, dest2, #output, #modules + 1))
else
    local dest = "Blossom/Blossom.lua"
    writeFile(dest, output)
    print(string.format("built: %s — %d bytes, %d modules", dest, #output, #modules + 1))
end
