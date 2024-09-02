import sys
import os
from runestone import build  # build is called implicitly by the paver driver.
from runestone import get_master_url
from socket import gethostname
import pkg_resources
from sphinxcontrib import paverutils
from runestone.server import get_dburl
import paver
from paver.easy import *
import paver.setuputils
paver.setuputils.install_distutils_tasks()

sys.path.append(os.getcwd())

# The project name, for use below.
project_name = os.path.basename(os.path.dirname(os.path.abspath(__file__)))

# use_services has to be == to the string 'true' to be activated and take profit
# of all the Runestone Server goodies
use_services = os.getenv('RUNESTONE_USE_SERVICES', 'false')
use_https = os.getenv('RUNESTONE_USE_HTTPS', False) == 'true'
protocol = 'https' if use_https else 'http'
runestone_host = os.getenv('RUNESTONE_HOST', 'localhost:8000')
master_url = '{proto}://{host}'.format(proto=protocol, host=runestone_host)
print('doi : master_url is set to', master_url)
if not master_url:
    master_url = get_master_url()

# uses the RUNESTONE_USE_DYNAMIC_PAGES from the env to determine whether we
# should activate dynamic pages. Inactive by default
use_dynamic_pages = os.environ.get(
    'RUNESTONE_USE_DYNAMIC_PAGES', False) == 'true'

# The root directory for ``runestone serve``.
serving_dir = "./build/" + project_name
# The destination directory for ``runestone deploy``.
dest = "./published"

options(
    sphinx=Bunch(docroot=".",),

    build=Bunch(
        builddir=serving_dir,
        sourcedir="_sources",
        outdir=serving_dir,
        confdir=".",
        template_args={'login_required': 'true',
                       'loglevel': 10,
                       'course_title': 'RS\\ Playground',
                       'python3': 'false',
                       'dburl': 'postgresql://user:password@localhost/runestone',
                       'default_ac_lang': 'python',
                       'jobe_server': 'http://jobe2.cosc.canterbury.ac.nz',
                       'proxy_uri_runs': '/jobe/index.php/restapi/runs/',
                       'proxy_uri_files': '/jobe/index.php/restapi/files/',
                       'downloads_enabled': 'true',
                       'minimal_outside_links': 'True',
                       'enable_chatcodes': 'true',
                       'allow_pairs': 'True',
                       'dynamic_pages': use_dynamic_pages,
                       'use_services': use_services,
                       'basecourse': project_name,
                       # If ``dynamic_pages`` is 'True', then the following values are ignored, since they're provided by the server.
                       'course_id': project_name,
                       'appname': 'runestone',
                       'course_url': master_url,
                       }
    )
)

# if we are on runestone-deploy then use the proxy server not canterbury
if gethostname() == 'runestone-deploy':
    del options.build.template_args['jobe_server']
    del options.build.template_args['proxy_uri_runs']
    del options.build.template_args['proxy_uri_files']

version = pkg_resources.require("runestone")[0].version
options.build.template_args['runestone_version'] = version

# If DBURL is in the environment override dburl
options.build.template_args['dburl'] = get_dburl(outer=locals())
