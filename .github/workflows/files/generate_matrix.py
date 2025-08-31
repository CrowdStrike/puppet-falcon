import argparse
import yaml
import json


parser = argparse.ArgumentParser(
    description='Generate a Github Actions matrix from a provision.yaml file.')

parser.add_argument('-p', '--path', type=str, help='The path to the provision.yaml file to be used.',
                    required=False, default='./provision.yaml')
parser.add_argument('-g', '--group', nargs='+', help='Provision groups to generate the matrix from. If not specified, all provision groups will be used.',
                    required=False, default=[])
parser.add_argument('-c', '--collection', nargs='+', help="Puppet versions to test against. If not specified `colleciton` will be used from the provision.yaml file.",
                    required=False, default=[])

args = parser.parse_args()


group = args.group
collection = args.collection

matrix = {
    'platforms': [],
    'collections': []
}


def image_tag(image):
    image_tag = image.split('/')[-1].replace(':', '-')
    return image_tag


def matrix_os(provisioner):
    if provisioner == 'vagrant':
        return 'macos-10.15'

    return 'ubuntu-latest'


try:
    with open(args.path, 'r') as f:
        provision_yaml = yaml.safe_load(f.read())
except FileNotFoundError:
    print(
        f"::error file={args.path},title=File Not Found::{args.path} does not exist.")

try:
    if len(group) > 0:
        # check if the provision groups exist
        for g in group:
            provision_group = provision_yaml.get(g)
            if provision_group is None:
                print(
                    f"::warning ::Provision group {g} does not exist in {args.path}")
                continue
            provisioner = provision_group['provisioner']
            for image in provision_group['images']:
                matrix['platforms'].append({
                    'provider': provisioner,
                    'image': image,
                    'label': image_tag(image),
                    'os': matrix_os(provisioner)
                })
    else:
        for group_name, value in provision_yaml.items():
            provisioner = value['provisioner']
            for image in value['images']:
                matrix['platforms'].append({
                    'provider': provisioner,
                    'image': image,
                    'label': image_tag(image),
                    'os': matrix_os(provisioner)
                })
except Exception as e:
    # TODO: More error handling to point out the issue.
    # Right now this is internal, and an error will be caused by an invalid
    # provision.yaml file.
    print(
        f"::error file={args.path}::{e}")


if len(collection) > 0:
    matrix['collections'] = collection
else:
    matrix['collections'] = provision_yaml['collections']

if matrix['platforms'] == []:
    print(
        f"::error ::Empy platform list. Check the provision.yaml file. {args.path} or pass in valid provision groups with -g")
if matrix['collections'] == []:
    print(
        f"::error ::Empy collection list. Check the provision.yaml file. {args.path} or pass in valid puppet collections with -c")

print("::set-output name=matrix::" + json.dumps(matrix))
