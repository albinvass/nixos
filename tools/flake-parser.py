import json
import pathlib
import argparse

from typing import Iterable, Union, Optional


class Locked:
    lastModified: int
    narHash: str
    owner: Optional[str]
    repo: Optional[str]
    rev: str
    revCount: Optional[int]
    type: str
    submodules: Optional[bool]
    url: Optional[str]

    def __init__(self, data) -> None:
        self.lastModified = data["lastModified"]
        self.narHash = data["narHash"]
        self.owner = data.get("owner")
        self.repo = data.get("repo")
        self.rev = data["rev"]
        self.revCount = data.get("rev")
        self.type = data["type"]
        self.url = data.get("url")

    def getCanonicalRepoUrl(self) -> str|None:
        match self.type:
            case "github": return f"https://github.com/{self.owner}/{self.repo}"
            case "sourcehut": return f"https://git.sr.ht/{self.owner}/{self.repo}"
            case "git": return self.url

    def toDict(self) -> dict:
        return {
            "lastModified": self.lastModified,
            "narHash": self.narHash,
            "owner": self.owner,
            "repo": self.repo,
            "rev": self.rev,
            "type": self.type,
            "_canonicalRepoUrl": self.getCanonicalRepoUrl()
        }

class Original:
    owner: Optional[str]
    repo: Optional[str]
    type: str

    def __init__(self, org):
        self.owner = org.get("owner")
        self.repo = org.get("repo")
        self.type = org["type"]

    def toDict(self):
        return {
            "owner": self.owner,
            "repo": self.repo,
            "type": self.type,
        }

class FlakeInput:
    flake: bool
    inputs: dict[str, 'Union[FlakeInput, Iterable[str]]']
    locked: Locked
    original: Original
    def __init__(self, name: str, nodes: dict):
        self.node = nodes[name]
        self.flake = self.node.get("flake", True)
        self.inputs = FlakeInput.parseInputs(name, nodes)
        self.locked = Locked(self.node["locked"])
        self.original = Original(self.node["original"])

    @staticmethod
    def parseInputs(name: str, nodes: dict) -> dict[str, 'Union[FlakeInput, Iterable[str]]']:
        inputs: dict[str, 'Union[FlakeInput, Iterable[str]]'] = {}
        for input_name, input in nodes[name].get("inputs", {}).items():
            if isinstance(input, list):
                inputs[input_name] = input
            if isinstance(input, str):
                inputs[input_name] = FlakeInput(input, nodes)


        return inputs

    def toDict(self):
        inputs = {}
        for key, input in self.inputs.items():
            if isinstance(input, FlakeInput):
                inputs[key] = input.toDict()
            else:
                inputs[key] = input
        return {
            "flake": self.flake,
            "inputs": inputs,
            "locked": self.locked.toDict(),
            "original": self.original.toDict(),
        }

def url_name_mapping(input_tree) -> dict[str, str]:
    result = {}
    for name, input in input_tree.items():
        if isinstance(input, dict):
            result[input["locked"]["_canonicalRepoUrl"]] = name
            result = result | url_name_mapping(input.get("inputs", {}))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("flake_ref", metavar="flake-ref")

    args = parser.parse_args()

    flake_lock_path = pathlib.Path(args.flake_ref) / "flake.lock"
    with flake_lock_path.open("r") as f:
        flake_lock = json.load(f)

    root_inputs = get_root_inputs(flake_lock)
    nodes = flake_lock["nodes"]

    input_tree = {}
    for name, key in root_inputs.items():
        input_tree[name] = FlakeInput(key, nodes).toDict()


    output = url_name_mapping(input_tree)

    print(json.dumps(output, indent=2))


def get_root_inputs(flake_lock: dict) -> dict:
    inputs = flake_lock["nodes"][flake_lock["root"]]["inputs"]
    return inputs


if __name__ == "__main__":
    main()
